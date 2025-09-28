#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
INPUT_FILE="out/dns-resolved.csv"
OUTPUT_FILE="out/edge-list.txt"

validacion_csv() {
  echo "--- Iniciando Fase de Validación del CSV ---"
  local cont_advertencia=0

  # Lee línea a línea sin hacks adicionales
  while IFS=',' read -r origen tipo destino ttl; do
    # omite líneas totalmente vacías
    if [[ -z "${origen:-}" && -z "${tipo:-}" && -z "${destino:-}" && -z "${ttl:-}" ]]; then
      continue
    fi

    if [[ -z "${origen:-}" || -z "${tipo:-}" || -z "${destino:-}" || -z "${ttl:-}" ]]; then
      echo "Advertencia: Línea con formato incompleto. Se omitirá."
      cont_advertencia=$((cont_advertencia + 1))
      continue
    fi

    if ! [[ "$ttl" =~ ^[0-9]+$ ]]; then
      echo "Advertencia: TTL no numérico ('$ttl') en la línea para '$origen'. Se omitirá."
      cont_advertencia=$((cont_advertencia + 1))
      continue
    fi
  done < "$INPUT_FILE"

  if [[ "$cont_advertencia" -gt 0 ]]; then
    echo "Error: Se encontraron ${cont_advertencia} errores de formato en el CSV. Abortando." >&2
    exit 1
  fi

  echo "Validación CSV OK. El formato es correcto."
}

procesar_csv() {
  echo "--- Iniciando Fase de Procesamiento y Conectividad ---"
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  : > "$OUTPUT_FILE"

  while IFS=',' read -r origen tipo destino ttl; do
    # seguridad adicional (ya validado)
    [[ -z "${origen:-}" && -z "${tipo:-}" && -z "${destino:-}" && -z "${ttl:-}" ]] && continue

    echo "$origen $destino" >> "$OUTPUT_FILE"

    if [[ "$tipo" == "A" ]]; then
      echo "-> [TEST] Probando conectividad a la IP $destino (Puerto 443)..."
      if command -v nc >/dev/null 2>&1; then
        nc -zvw1 "$destino" 443 || true
      fi
    fi
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
  echo "Iniciando el script para parsear el CSV"

  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error el archivo de entrada '$INPUT_FILE' no existe." >&2
    exit 1
  fi

  validacion_csv
  procesar_csv
  generar_grafo

  echo "Proceso completado. El resultado está en '$OUTPUT_FILE'."
}

main "$@"
