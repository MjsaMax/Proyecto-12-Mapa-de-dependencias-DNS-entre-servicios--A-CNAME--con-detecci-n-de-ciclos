#!/usr/bin/env bash
set -euo pipefail

# --- Variables de Entorno ---
echo "Usando archivo de dominios: ${DOMAINS_FILE}"
echo "Usando servidor DNS: ${DNS_SERVER}"
echo "---------------------------------"

resolve_domains() {
  while IFS= read -r domain || [[ -n "$domain" ]]; do
    if [[ -z "$domain" ]]; then
      continue
    fi

    dig @"${DNS_SERVER}" +short +ttl "$domain" A | awk -v d="$domain" '{print d ",A," $4 "," $1}'
    dig @"${DNS_SERVER}" +short +ttl "$domain" CNAME | awk -v d="$domain" '{print d ",CNAME," $4 "," $1}'

  done < "${DOMAINS_FILE}"
}

mkdir -p out
resolve_domains | sort | uniq > out/dns-resolved.csv
echo "Proceso completado. Resultados en out/dns-resolved.csv"