#!/bin/bash

set -euo pipefail

# --- Variables de configuración ---
INPUT_FILE="out/dns-resolved.csv"
OUTPUT_FILE="out/edge-list.txt"

## --- Sección para luego implementar el script--- 
validacion_csv(){
    echo "--- Iniciando Fase de Validación del CSV ---"
    local cont_advertencia=0
    
    while IFS=',' read -r origen tipo destino ttl; do
        if [ -z "$origen" ] || [ -z "$tipo" ] || [ -z "$destino" ] || [ -z "$ttl" ]; then
            echo "Advertencia: Línea con formato incompleto. Se omitirá."
            ((cont_advertencia++))
            continue  
        fi

        if ! [[ "$ttl" =~ ^[0-9]+$ ]]; then
            echo "Advertencia: TTL no numérico ('$ttl') en la línea para '$origen'. Se omitirá."
            ((cont_advertencia++))
            continue
        fi
    done < "$INPUT_FILE"

    if [ "$cont_advertencia" -gt 0 ]; then
        echo "Error: Se encontraron ${cont_advertencia} errores de formato en el CSV. Abortando."
        exit 1
    fi

    # Imprime el mensaje una sola vez si todo está correcto
    echo "Validación CSV OK. El formato es correcto."
}

procesar_csv() {
    echo "--- Iniciando Fase de Procesamiento y Conectividad ---"
    > "$OUTPUT_FILE"

    while IFS=',' read -r origen tipo destino ttl; do
        echo "$origen $destino" >> "$OUTPUT_FILE"

        if [[ "$tipo" == "A" ]]; then
            echo "-> [TEST] Probando conectividad a la IP $destino (Puerto 443)..."
            nc -zvw1 "$destino" 443 || true
        fi
    done < "$INPUT_FILE"
}

generar_grafo(){
    echo "--- Iniciando fase de generación de grafo ---"

    local grafo_output="out/preview.grafo.dot"

    echo "Generadno archivo de visualización en '${grafo_output}'..."
    {
        echo "digraph DNS {"
        awk '{print "\"" $1 "\" -> \"" $2 "\";"}' "$OUTPUT_FILE"
        echo "}"
    } > "$grafo_output"
 }


main(){
   
    echo "Iniciando el script para parsear el CSV"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error el archivo de entrada '$INPUT_FILE' no existe."
        exit 1
    fi

    validacion_csv
    procesar_csv
    generar_grafo

    echo "Proceso completado. El resultado está en '$OUTPUT_FILE'."
        
}

## LLamada a la función para ejecutar el script
main