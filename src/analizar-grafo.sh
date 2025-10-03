#!/usr/bin/env bash
set -euo pipefail

# --- Configuración de Archivos ---
INPUT_FILE="out/dns-resolved.json"
OUTPUT_FILE="out/edge-list.txt"
GRAFO_OUTPUT="out/preview.grafo.dot"

# --- Variables Globales para el Análisis ---
declare -A GRAFO # Array asociativo para guardar el grafo (origen -> lista de destinos)
declare -A METRICAS # Array para guardar los resultados del análisis

# --- Funciones ---

# Verifica que las dependencias (como jq) estén instaladas.
verificar_dependencias() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: se requiere 'jq' para procesar JSON." >&2
        exit 127
    fi
}

# Lee el archivo JSON, lo valida y construye el grafo en memoria.
construir_grafo(){
    echo "--- Iniciando Fase de Validación y Construcción del Grafo ---"
    local cont_advertencia=0
    : > "$OUTPUT_FILE" # Limpia el archivo de salida al inicio

    set +e # Desactiva la salida por error para el bucle while-read
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        # --- Validación de cada línea JSON ---
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

        # --- Procesamiento y construcción del grafo ---
        local origen=$(echo "$line" | jq -r '.domain')
        local destino=$(echo "$line" | jq -r '.value')

        GRAFO["$origen"]+="$destino "
        echo "$origen $destino" >> "$OUTPUT_FILE"

    done < "$INPUT_FILE"
    set -e # Reactiva la salida por error

    if [[ "$cont_advertencia" -gt 0 ]]; then
        echo "Error: Se encontraron ${cont_advertencia} errores de formato en el JSON. Abortando." >&2
        exit 1
    fi

    echo "Validación y construcción del grafo OK."
    METRICAS["nodos"]=${#GRAFO[@]}
}

# --- Variables para el Análisis Recursivo ---
ciclos_detectados=0
profundidad_maxima=0

# Función recursiva para recorrer el grafo (DFS).
_recorrer_dfs() {
    local nodo_actual="$1"
    local profundidad_actual="$2"
    shift 2 # El resto de los argumentos ($@) son la ruta actual
    local ruta_actual=("$@")

    # Detección de Ciclos
    for nodo_en_ruta in "${ruta_actual[@]}"; do
        if [[ "$nodo_en_ruta" == "$nodo_actual" ]]; then
            echo "CICLO DETECTADO: ${ruta_actual[*]} -> $nodo_actual"
            ciclos_detectados=$((ciclos_detectados + 1))
            return # Termina esta rama para evitar un bucle infinito
        fi
    done

    # Si el nodo actual no tiene más destinos, hemos llegado al final de un camino
    if [[ -z "${GRAFO[$nodo_actual]:-}" ]]; then
        if (( profundidad_actual > profundidad_maxima )); then
            profundidad_maxima=$profundidad_actual
        fi
        return
    fi

    # Paso Recursivo: explora cada destino del nodo actual
    local destinos=(${GRAFO[$nodo_actual]})
    for proximo_nodo in "${destinos[@]}"; do
        _recorrer_dfs "$proximo_nodo" "$((profundidad_actual + 1))" "${ruta_actual[@]}" "$nodo_actual"
    done
}

# Orquesta el análisis del grafo.
analizar_grafo() {
    echo "--- Iniciando Fase de Análisis del Grafo ---"
    # Inicia un recorrido DFS para cada origen en el grafo
    for origen in "${!GRAFO[@]}"; do
        _recorrer_dfs "$origen" 0
    done

    # Guarda los resultados finales en el array de métricas
    METRICAS["ciclos"]="$ciclos_detectados"
    METRICAS["profundidad_maxima"]="$profundidad_maxima"
}

# Imprime las métricas finales en la consola.
imprime_metricas() {
    echo "--- Exportando Métricas del Análisis ---"
    echo "Número de nodos: ${METRICAS["nodos"]}"
    echo "Ciclos detectados: ${METRICAS["ciclos"]}"
    echo "Profundidad máxima: ${METRICAS["profundidad_maxima"]}"
}

# Genera el archivo .dot para visualización con Graphviz.
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

# Función principal que orquesta todo el flujo.
main() {
    echo "Iniciando el script para analizar el JSON de DNS"
    verificar_dependencias

    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Error: El archivo de entrada '$INPUT_FILE' no existe." >&2
        exit 1
    fi

    construir_grafo
    analizar_grafo
    generar_grafo 
    imprime_metricas

    echo "Proceso completado. El resultado está en '$OUTPUT_FILE'."
}

main "$@"