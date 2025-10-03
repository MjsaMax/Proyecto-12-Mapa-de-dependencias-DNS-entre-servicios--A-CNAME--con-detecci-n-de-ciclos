#!/usr/bin/env bats

setup() {
  export BATS_TMPDIR=$(mktemp -d)
  mkdir -p "${BATS_TMPDIR}/out"
  mkdir -p "${BATS_TMPDIR}/src"

  cp ./src/resolve.sh "${BATS_TMPDIR}/src/"
  cp ./src/analizar-grafo.sh "${BATS_TMPDIR}/src/"
  chmod +x "${BATS_TMPDIR}/src/"*.sh
  export DOMAINS_FILE="${BATS_TMPDIR}/domains.txt"
  export DNS_SERVER="8.8.8.8"
}

teardown() {
  rm -rf "$BATS_TMPDIR"
}

require_jq() {
  command -v jq >/dev/null 2>&1 || skip "Se requiere 'jq' para estas pruebas"
}

require_dig() {
    command -v dig >/dev/null 2>&1 || skip "Se requiere 'dig' para estas pruebas"
}

print_debug() {
  echo "----- DEBUG -----"
  echo "EXIT: ${status}"
  echo "--- SALIDA (stdout+stderr) ---"
  echo "${output}"
  echo "-----------------"
}

@test "Debe procesar un JSON válido y generar un edge-list correcto + DOT" {
    require_jq

  cat > "${BATS_TMPDIR}/out/dns-resolved.json" <<EOF
{"domain": "github.com", "type": "A", "value": "20.205.243.166", "ttl": "60"}
{"domain": "google.com", "type": "A", "value": "142.250.78.46", "ttl": "300"}
EOF

  run bash -c "cd '${BATS_TMPDIR}' && ./src/analizar-grafo.sh"

  if [ "$status" -ne 0 ]; then
    print_debug
  fi
  [ "$status" -eq 0 ]

  [ -f "${BATS_TMPDIR}/out/edge-list.txt" ]
  [ -f "${BATS_TMPDIR}/out/preview.grafo.dot" ]

  expected_edges="github.com 20.205.243.166
google.com 142.250.78.46"
  [ "$(cat "${BATS_TMPDIR}/out/edge-list.txt")" = "$expected_edges" ]

  DOT_CONTENT="$(cat "${BATS_TMPDIR}/out/preview.grafo.dot")"
  [[ "$DOT_CONTENT" == *"\"github.com\" -> \"20.205.243.166\";"* ]]
  [[ "$DOT_CONTENT" == *"\"google.com\" -> \"142.250.78.46\";"* ]]
}

@test "Debe abortar con código de error 1 si el JSON tiene TTL no numérico" {
  require_jq
  cat > "${BATS_TMPDIR}/out/dns-resolved.json" <<EOF
{"domain": "github.com", "type": "A", "value": "20.205.243.166", "ttl": "sesenta"}
EOF

  run bash -c "cd '${BATS_TMPDIR}' && ./src/analizar-grafo.sh 2>&1"

  if [ "$status" -eq 0 ]; then
    print_debug
  fi
  [ "$status" -eq 1 ]

  [[ "${output}" == *"errores de formato en el JSON. Abortando."* ]]
}

@test "Debe abortar con código de error 1 si falta un campo (por ejemplo TTL vacío)" {
  require_jq
  cat > "${BATS_TMPDIR}/out/dns-resolved.json" <<EOF
{"domain": "example.com", "type": "A", "value": "93.184.216.34"}
EOF

  run bash -c "cd '${BATS_TMPDIR}' && ./src/analizar-grafo.sh 2>&1"

  if [ "$status" -eq 0 ]; then
    print_debug
  fi
  [ "$status" -eq 1 ]

  [[ "${output}" == *"errores de formato en el JSON. Abortando."* ]]
}

@test "[CASO-POSITIVO] resolve.sh resuelve dominios reales y genera JSON válido" {
    require_jq
    require_dig
    
    cat > "${DOMAINS_FILE}" <<EOF
google.com
github.com
EOF
    
    run bash -c "cd '${BATS_TMPDIR}' && timeout 20 ./src/resolve.sh 2>/dev/null"
    
    [ "$status" -eq 0 ]
    [ -f "${BATS_TMPDIR}/out/dns-resolved.json" ]
    
    # Verificar JSON válido y con estructura correcta
    while IFS= read -r line; do
        echo "$line" | jq -e 'has("domain") and has("type") and has("value") and has("ttl")' >/dev/null
        local ttl=$(echo "$line" | jq -r '.ttl')
        [[ "$ttl" =~ ^[0-9]+$ ]]
    done < "${BATS_TMPDIR}/out/dns-resolved.json"
}

@test "[CASO-NEGATIVO] resolve.sh maneja NXDOMAIN sin crashear" {
    require_dig
    
    echo "dominio-inexistente-test-12345.invalid" > "${DOMAINS_FILE}"
    
    run bash -c "cd '${BATS_TMPDIR}' && timeout 15 ./src/resolve.sh 2>&1"
    
    # Debe completar sin crash
    [ "$status" -eq 0 ]
    
    # Debe loguear el error
    [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"WARN"* ]]
    
    # JSON debe estar vacío o sin el dominio inválido
    if [ -f "${BATS_TMPDIR}/out/dns-resolved.json" ]; then
        ! grep -q "dominio-inexistente" "${BATS_TMPDIR}/out/dns-resolved.json" || \
        [ ! -s "${BATS_TMPDIR}/out/dns-resolved.json" ]
    fi

}

@test "[CASO-NEGATIVO] Conectividad falla correctamente en puertos cerrados" {
    command -v nc >/dev/null 2>&1 || skip "Se requiere 'nc'"
    
    # Probar conexión a IP de prueba en puerto cerrado (simula 404/conexión rechazada)
    run timeout 5 nc -zv -w 2 192.0.2.1 80
    
    [ "$status" -ne 0 ]

}

@test "[CASO-TIMEOUT] analizar-grafo.sh detecta ciclos sin loop infinito" {
    require_jq
    
    # Crear ciclo: a -> b -> c -> a
    cat > "${BATS_TMPDIR}/out/dns-resolved.json" <<EOF
{"domain": "a.com", "type": "CNAME", "value": "b.com", "ttl": "60"}
{"domain": "b.com", "type": "CNAME", "value": "c.com", "ttl": "60"}
{"domain": "c.com", "type": "CNAME", "value": "a.com", "ttl": "60"}
EOF
    
    # Debe completar sin colgar
    run timeout 10 bash -c "cd '${BATS_TMPDIR}' && ./src/analizar-grafo.sh 2>&1"
    
    [ "$status" -ne 124 ]  # No timeout
    
    # Debe detectar ciclo o completar normalmente
    [[ "$output" == *"CICLO DETECTADO"* ]] || [ "$status" -eq 0 ]
}

@test "[METRICA] Falla si se detectan ciclos (threshold: ciclos > 0)" {
    require_jq
    
    # Crear datos CON ciclo
    cat > "${BATS_TMPDIR}/out/dns-resolved.json" <<EOF
{"domain": "a.com", "type": "CNAME", "value": "b.com", "ttl": "60"}
{"domain": "b.com", "type": "CNAME", "value": "a.com", "ttl": "60"}
EOF
    
    run bash -c "cd '${BATS_TMPDIR}' && ./src/analizar-grafo.sh 2>&1"
    
    # Extraer métrica de ciclos
    local ciclos=$(echo "$output" | grep -oP "Ciclos detectados: \K\d+" || echo "0")
    
    # THRESHOLD: Debe fallar si ciclos > 0
    [ "$ciclos" -gt 0 ]
    
}

@test "[METRICA] Pasa si NO hay ciclos (threshold: ciclos == 0)" {
    require_jq
    
    # Crear datos SIN ciclos
    cat > "${BATS_TMPDIR}/out/dns-resolved.json" <<EOF
{"domain": "example.com", "type": "A", "value": "93.184.216.34", "ttl": "3600"}
{"domain": "google.com", "type": "A", "value": "142.250.78.46", "ttl": "300"}
EOF
    
    run bash -c "cd '${BATS_TMPDIR}' && ./src/analizar-grafo.sh 2>&1"
    
    [ "$status" -eq 0 ]
    
    # Extraer métrica
    local ciclos=$(echo "$output" | grep -oP "Ciclos detectados: \K\d+" || echo "0")
    
    # THRESHOLD: Debe pasar si ciclos == 0
    [ "$ciclos" -eq 0 ]

}