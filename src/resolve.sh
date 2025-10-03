#!/usr/bin/env bash
set -euo pipefail

log() {
    local level="$1"
    local message="$2"
    echo "{\"timestamp\": \"$(date +'%Y-%m-%d %H:%M:%S')\", \"level\": \"${level}\", \"message\": \"${message}\"}" >&2
}

cleanup() {
    log "INFO" "Interrupción recibida, terminando de forma ordenada."
    exit 0
}
trap cleanup SIGINT SIGTERM

check_connectivity() {
    local ip="$1"
    local ports=("80" "443")

    for port in "${ports[@]}"; do
        if nc -zv -w 2 "$ip" "$port" &>/dev/null; then
            log "INFO" "Conectividad exitosa con ${ip} en el puerto ${port}."
        else
            log "WARN" "No se pudo establecer conexión con ${ip} en el puerto ${port}."
        fi
    done
}

# --- FUNCIÓN RECURSIVA para resolver un dominio hasta el final ---
resolve_recursive() {
    local domain_to_check="$1"
    
    local cname_output
    cname_output=$(dig @"${DNS_SERVER:-8.8.8.8}" +noall +answer "$domain_to_check" CNAME)

    if [[ -n "$cname_output" ]]; then
        local next_domain=$(echo "$cname_output" | awk '{print $5}')
        next_domain=${next_domain%.} 
        local ttl=$(echo "$cname_output" | awk '{print $2}')
        
        log "INFO" "CNAME encontrado para ${domain_to_check}: ${next_domain}"
        
        echo "{\"domain\": \"${domain_to_check}\", \"type\": \"CNAME\", \"value\": \"${next_domain}\", \"ttl\": \"${ttl}\"}"
        
        resolve_recursive "$next_domain"
        return
    fi

    local a_output
    a_output=$(dig @"${DNS_SERVER:-8.8.8.8}" +noall +answer "$domain_to_check" A)
    if [[ -n "$a_output" ]]; then
        log "INFO" "Registro A encontrado para ${domain_to_check}"
        
        while read -r line; do
            if [[ -z "$line" ]]; then continue; fi
            
            local ip=$(echo "$line" | awk '{print $5}')
            local ttl=$(echo "$line" | awk '{print $2}')
            
            echo "{\"domain\": \"${domain_to_check}\", \"type\": \"A\", \"value\": \"${ip}\", \"ttl\": \"${ttl}\"}"
            
            check_connectivity "$ip"
        done <<< "$a_output"
        return
    fi

    log "ERROR" "No se encontraron registros A o CNAME para ${domain_to_check}"
}

# --- FUNCIÓN PRINCIPAL ---
main() {
    log "INFO" "Iniciando resolución recursiva de dominios..."
    log "INFO" "Usando archivo de dominios: ${DOMAINS_FILE}"
    log "INFO" "Usando servidor DNS: ${DNS_SERVER:-8.8.8.8}"

    while IFS= read -r domain || [[ -n "$domain" ]]; do
        if [[ -z "$domain" ]]; then continue; fi
        log "INFO" "--- Procesando dominio original: ${domain} ---"
        resolve_recursive "$domain"
    done < "${DOMAINS_FILE}"

    log "INFO" "Proceso de resolución completado."
}

# --- Ejecución ---
: "${DOMAINS_FILE:?La variable de entorno DOMAINS_FILE debe estar definida}"
: "${DNS_SERVER:=8.8.8.8}"
mkdir -p out
main