#!/bin/bash

set -euo pipefail

# --- Variables de configuración ---
INPUT_FILE="out/dns-resolved.csv"
OUTPUT_FILE="out/edge-list.txt"

## --- Sección para luego implementar el script--- 
main(){

    echo "Iniciando el script para parsear el CSV"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error el archivo de entrada '$INPUT_FILE' no existe."
        exit 1
    fi

    #Borrando el archivo de salida si es que ya existe

    > "$OUTPUT_FILE"

    while IFS=',' read -r origen tipo destino ttl; do
        if [ -z "$destino" ] && [ -n "$ttl" ]; then
            echo "Advertencia: Corregido formato anómalo para el dominio '$origen'."
            destino="$ttl"
            ttl="0"
        fi

        if [ -z "$origen" ] || [ -z "$tipo" ] || [ -z "$destino" ] || [ -z "$ttl" ]; then
            echo "Advertencia: Línea con formato incompleto (no tiene 4 columnas). Se omitirá."
            continue  
        fi

        if ! [[ "$ttl" =~ ^[0-9]+$ ]]; then
            echo "Advertencia: TTL no numérico ('$ttl') en la línea para '$origen'. Se omitirá."
            continue
        fi

        if [ -z "$origen" ] || [ -z "$destino" ]; then
            echo "Advertencia: Línea con formato incorrecto."
            continue  
        fi    
        
        echo "$origen $destino" >> "$OUTPUT_FILE"
    
    done < "$INPUT_FILE"

    echo "Proceso completado. El resultado está en '$OUTPUT_FILE'."
        
}

## LLamada a la función para ejecutar el script
main