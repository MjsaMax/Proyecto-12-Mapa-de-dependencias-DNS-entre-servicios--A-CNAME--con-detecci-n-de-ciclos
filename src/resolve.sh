#!/usr/bin/env bash
set -euo pipefail

# --- Función de Logging Estructurado ---
# Tarea: Logs estructurados con timestamp/level.
log() {
  local level="$1"
  local message="$2"
echo "{\"timestamp\": \"$(date +'%Y-%m-%d %H:%M:%S')\", \"level\": \"${level}\", \"message\": \"${message}\"}" >&2
}

# --- Función de Limpieza para trap ---
# Tarea: trap para SIGINT/SIGTERM.
cleanup() {
  log "INFO" "Interrupción recibida, terminando de forma ordenada."
  exit 0
}
trap cleanup SIGINT SIGTERM

# --- Variables de Entorno ---
log "INFO" "Usando archivo de dominios: ${DOMAINS_FILE}"
log "INFO" "Usando servidor DNS: ${DNS_SERVER}"

# --- Función de Verificación de Conectividad ---
# Tarea: Verificar conectividad final con ss o nc -zv.
check_connectivity() {
  local ip="$1"
  local ports=("80" "443") # Puertos comunes a verificar (HTTP, HTTPS)

  for port in "${ports[@]}"; do
    # Usamos nc con timeout de 2 segundos (-w 2)
    if nc -zv -w 2 "$ip" "$port" &>/dev/null; then
      log "INFO" "Conectividad exitosa con ${ip} en el puerto ${port}."
    else
      log "WARN" "No se pudo establecer conexión con ${ip} en el puerto ${port}."
    fi
  done
}

# --- Función Principal ---
# --- Función Principal (CORREGIDA)---
resolve_domains() {
  while IFS= read -r domain || [[ -n "$domain" ]]; do
    domain=$(echo "$domain" | tr -d '\r')
    if [[ -z "$domain" ]]; then continue; fi

    log "INFO" "Procesando dominio: ${domain}" >&2

    # --- BÚSQUEDA DE REGISTROS A ---
    local max_retries=3
    local dig_output_A=""
    for i in $(seq 1 "$max_retries"); do
      dig_output_A=$(dig @"${DNS_SERVER}" +time=3 +tries=1 +noall +answer "$domain" A || true)
      if [[ -n "$dig_output_A" ]]; then
        log "INFO" "Resolución A para ${domain} exitosa en intento ${i}." >&2
        break
      else
        log "WARN" "Intento ${i}/${max_retries} (A) falló para ${domain}." >&2
        sleep 1
      fi
    done

    # Si la búsqueda de A fue exitosa, procesamos los resultados
    if [[ -n "$dig_output_A" ]]; then
      while read -r line; do
          local ip=$(echo "$line" | awk '{print $5}')
          local ttl=$(echo "$line" | awk '{print $2}')
          # La salida de datos JSON va a stdout (sin >&2)
          echo "{\"domain\": \"${domain}\", \"type\": \"A\", \"value\": \"${ip}\", \"ttl\": \"${ttl}\"}"
          check_connectivity "$ip"
      done <<< "$dig_output_A"
    else
      log "ERROR" "No se pudo resolver registro A para ${domain} después de ${max_retries} intentos." >&2
    fi

    # --- BÚSQUEDA DE REGISTROS CNAME (PROCESO SEPARADO) ---
    local dig_output_cname=""
    for i in $(seq 1 "$max_retries"); do
      dig_output_cname=$(dig @"${DNS_SERVER}" +time=3 +tries=1 +noall +answer "$domain" CNAME || true)
      if [[ -n "$dig_output_cname" ]]; then
        log "INFO" "Resolución CNAME para ${domain} exitosa en intento ${i}." >&2
        break
      fi
    done
    
    # Si la búsqueda de CNAME fue exitosa, la procesamos
    if [[ -n "$dig_output_cname" ]]; then
        while read -r line; do
            local cname_val=$(echo "$line" | awk '{print $5}')
            local ttl=$(echo "$line" | awk '{print $2}')
            echo "{\"domain\": \"${domain}\", \"type\": \"CNAME\", \"value\": \"${cname_val}\", \"ttl\": \"${ttl}\"}"
        done <<< "$dig_output_cname"
    fi

  done < "${DOMAINS_FILE}"
}

# --- Ejecución ---
mkdir -p out

# Los logs (INFO, WARN, ERROR) van a la terminal/stderr y a un archivo de log.
# La salida de datos (JSON) va a stdout y se redirige al archivo de resultados.
resolve_domains | tee out/dns-resolved.json
#echo "Proceso completado. Resultados en out/dns-resolved.csv"

