#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
INPUT_FILE="out/dns-resolved.json"
OUTPUT_FILE="out/edge-list.txt"
GRAFO_OUTPUT="out/preview.grafo.dot"

declare -A GRAFO #Array para guardar el grafo(orgine ->destino)
declare -A METRICAS #Array de resultados del análisis

verificar_dependencias() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: se requiere 'jq' para procesar JSON." >&2
    exit 127
  fi
}

construir_grafo(){

  echo "--- Iniciando Fase de Validación y Construcción del Grafo ---"
  local cont_advertencia=0
  : > "$OUTPUT_FILE"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    # --- Validación ---
    if ! echo "$line" | jq -e 'has("domain") and has("type") and has("value") and has("ttl")' > /dev/null; then
      echo "Advertencia: Línea JSON con estructura inválida. Se omitirá."
      cont_advertencia=$((cont_advertencia + 1))        
      continue
    fi

    if ! echo "$line" | jq -e '.ttl | tostring | test("^[0-9]+$")' > /dev/null; then
        echo "Advertencia: TTL no numérico. Se omitirá."
        cont_advertencia=$((cont_advertencia + 1))
        continue
    fi

    # --- Procesamiento ---
    local origen=$(echo "$line" | jq -r '.domain')
    local destino=$(echo "$line" | jq -r '.value')

    GRAFO["$origen"]="$destino"
    echo "$origen $destino" >> "$OUTPUT_FILE"

  done < "$INPUT_FILE"

  if [[ "$cont_advertencia" -gt 0 ]]; then
      echo "Error: Se encontraron ${cont_advertencia} errores de formato en el JSON. Abortando." >&2
      exit 1
  fi

  echo "Validación y construcción del grafo OK."
  METRICAS["nodos"]=${#GRAFO[@]}
}

analizar_grafo() {
  echo "--- Iniciando Fase de Análisis del Grafo ---"
  local ciclos_detectados=0
  local profundidad_maxima=0

  for origen in "${!GRAFO[@]}"; do
    local ruta_actual=()
    local nodo_actual="$origen"
    local profundidad_actual=0

    while [[ -n "${GRAFO[$nodo_actual]:-}" ]]; do
        for nodo_en_ruta in "${ruta_actual[@]}"; do
          if [[ "$nodo_en_ruta" == "$nodo_actual" ]]; then
            echo "CICLO DETECTADO: ${ruta_actual[*]} -> $nodo_actual"
            ciclos_detectados=$((ciclos_detectados + 1))
            nodo_actual="" 
            break
          fi

        done
        [[ -z "$nodo_actual" ]] && break

        ruta_actual+=("$nodo_actual")
        nodo_actual="${GRAFO[$nodo_actual]}"
        profundidad_actual=$((profundidad_actual + 1))
    done

    (( profundidad_actual > profundidad_maxima )) && profundidad_maxima=$profundidad_actual
  done

  METRICAS["ciclos"]="$ciclos_detectados"
  METRICAS["profundidad_maxima"]="$profundidad_maxima"
}

imprime_metricas() {
    echo "--- Exportando Métricas del Análisis ---"
    echo "Número de nodos: ${METRICAS["nodos"]}"
    echo "Ciclos detectados: ${METRICAS["ciclos"]}"
    echo "Profundidad máxima: ${METRICAS["profundidad_maxima"]}"
}

generar_grafo() {
  echo "--- Iniciando fase de generación de grafo ---"
  mkdir -p "$(dirname "$GRAFO_OUTPUT")"
  echo "Generando archivo de visualización en '${GRAFO_OUTPUT}'..."
  {
    echo "digraph DNS {"
    awk '{printf "\"%s\" -> \"%s\";\n", $1, $2}' "$OUTPUT_FILE"
    echo "}"
  } > "$GRAFO_OUTPUT"
}

main() {
  echo "Iniciando el script para analizar el JSON de DNS"

  verificar_dependencias

  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error el archivo de entrada '$INPUT_FILE' no existe." >&2
    exit 1
  fi

  : > "$OUTPUT_FILE"

    construir_grafo
    analizar_grafo
    generar_grafo 
    imprime_metricas

  echo "Proceso completado. El resultado está en '$OUTPUT_FILE'."
}

main "$@"
