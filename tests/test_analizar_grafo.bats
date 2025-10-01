#!/usr/bin/env bats

setup() {
  BATS_TMPDIR=$(mktemp -d)
  mkdir -p "${BATS_TMPDIR}/out"
  mkdir -p "${BATS_TMPDIR}/src"

  cp ./src/analizar-grafo.sh "${BATS_TMPDIR}/src/"
  chmod +x "${BATS_TMPDIR}/src/analizar-grafo.sh"
}

teardown() {
  rm -rf "$BATS_TMPDIR"
}

require_jq() {
  command -v jq >/dev/null 2>&1 || skip "Se requiere 'jq' para estas pruebas"
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
