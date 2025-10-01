#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
INPUT_FILE="out/dns-resolved.json"
OUTPUT_FILE="out/edge-list.txt"

validacion_json() {
  echo "--- Iniciando Fase de Validación del JSON ---"
  local cont_advertencia=0

  # Lee ela rchivo 
  while read -r line; do
    # omite líneas totalmente vacías
    if [[ -z "$line" ]]; then continue; fi

    if ! echo "$line" | jq -e 'has("domain") and has("type") and has("value") and has("ttl")' > /dev/null; then
        echo "Advertencia: Línea JSON con estructura inválida (faltan campos). Se omitirá."
        ((cont_advertencia++))
        continue
    fi

    if ! echo "$line" | jq -e '.ttl | test("^[0-9]+$")' > /dev/null; then
        local domain_val=$(echo "$line" | jq -r '.domain')
        local ttl_val=$(echo "$line" | jq -r '.ttl')
        echo "Advertencia: TTL no numérico ('${ttl_val}') en la línea para '${domain_val}'. Se omitirá."
        ((cont_advertencia++))
        continue
    fi
  done < "$INPUT_FILE"

  if [[ "$cont_advertencia" -gt 0 ]]; then
    echo "Error: Se encontraron ${cont_advertencia} errores de formato en el CSV. Abortando." >&2
    exit 1
  fi

  echo "Validación JSON OK. El formato es correcto."
}

procesar_json() {
  echo "--- Iniciando Fase de Procesamiento y Conectividad ---"
  > "$OUTPUT_FILE"

  while read -r line; do    
    if [[ -z "$line" ]]; then continue; fi
    
    local origen=$(echo "$line" | jq -r '.domain')
    local tipo=$(echo "$line" | jq -r '.type')
    local destino=$(echo "$line" | jq -r '.value')
    local ttl=$(echo "$line" | jq -r '.ttl')
    
    echo "$origen $destino" >> "$OUTPUT_FILE"

    # NOTA: Mi compañero de la rama 1 hizo esta prueba para el sprint 2.
    #if [[ "$tipo" == "A" ]]; then
        # echo "-> [TEST] Probando conectividad a la IP $destino (Puerto 443)..."
        # nc -zvw1 "$destino" 443 || true
        : #  nada
    #fi
  done < "$INPUT_FILE"
}

generar_grafo() {
  echo "--- Iniciando fase de generación de grafo ---"
  local grafo_output="out/preview.grafo.dot"
  mkdir -p "$(dirname "$grafo_output")"
  echo "Generando archivo de visualización en '${grafo_output}'..."
  {
    echo "digraph DNS {"
    awk '{printf "\"%s\" -> \"%s\";\n", $1, $2}' "$OUTPUT_FILE"
    echo "}"
  } > "$grafo_output"
}

main() {
  echo "Iniciando el script para analizar el JSON de DNS"

  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error el archivo de entrada '$INPUT_FILE' no existe." >&2
    exit 1
  fi

  validacion_json
  procesar_json
  generar_grafo

  echo "Proceso completado. El resultado está en '$OUTPUT_FILE'."
}

main "$@"
