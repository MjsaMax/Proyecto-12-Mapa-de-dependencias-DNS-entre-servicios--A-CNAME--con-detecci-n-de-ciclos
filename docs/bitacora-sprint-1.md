# Bitácora Sprint 1 - Rama: feature/resolve-dns-Davila-Aaron

**Responsable:** Aaron Davila Santos 
**Fecha:** 26 de septiembre de 2025

## 1. Objetivo
Implementar un script en Bash para la resolución de dominios (registros A/CNAME) a partir de una lista, generando una salida limpia en formato CSV.

## 2. Comandos y Evidencias de Ejecución Exitosa

**Ejecución del script:**
```bash
# Se exportan las variables de entorno requeridas
export DOMAINS_FILE="config/domains.txt"
export DNS_SERVER="8.8.8.8"

# Se ejecuta el script desde la raíz del proyecto
./src/resolve.sh
