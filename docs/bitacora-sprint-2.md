# Bitácora Sprint 2 - Rama: feature/resolve-dns

**Responsable:** Aaron Davila Santos
**Fecha:** 30 de septiembre de 2025

## 1. Objetivo del Sprint
El objetivo de este sprint fue robustecer el script de resolución de DNS, añadiendo manejo de errores avanzado, resiliencia a fallos de red y una capa de validación de conectividad para los resultados obtenidos.

## 2. Nuevas Funcionalidades Implementadas
Se implementaron las siguientes mejoras clave en el script `resolve_dns.sh`:

* **Logs Estructurados (JSON)**: Se creó una función `log` que genera logs en formato JSON y los envía a `stderr` para separar los datos de los diagnósticos.
* **Manejo de Señales (`trap`)**: El script ahora captura las interrupciones (Ctrl+C) para terminar de forma limpia y ordenada.
* **Reintentos y Timeouts**: Las consultas `dig` ahora tienen un timeout de 3 segundos y se reintentan hasta 3 veces en caso de fallo, lo que aumenta la resiliencia ante problemas transitorios de red.
* **Verificación de Conectividad**: Después de resolver una IP (registro A), el script utiliza `nc` para verificar si los puertos 80 y 443 están abiertos, añadiendo una validación extra.

## 3. Comandos y Evidencias

**Comando de Ejecución:**
```bash
# Exportar variables y ejecutar el script.
# La salida de datos (stdout) se guarda en dns-resolved.json.
# La salida de logs (stderr) se guarda en sprint2.log.
export DOMAINS_FILE="config/domains.txt"
export DNS_SERVER="8.8.8.8"
./src/resolve.sh > out/dns-resolved.json 2> out/sprint2.log
```
**Ejemplo de Salida de Datos (out/dns-resolved.json):**
```bash
{"domain": "google.com", "type": "A", "value": "172.217.192.101", "ttl": "35"}
{"domain": "google.com", "type": "A", "value": "172.217.192.138", "ttl": "35"}
{"domain": "google.com", "type": "A", "value": "172.217.192.100", "ttl": "35"}
{"domain": "google.com", "type": "A", "value": "172.217.192.102", "ttl": "35"}
{"domain": "google.com", "type": "A", "value": "172.217.192.139", "ttl": "35"}
{"domain": "google.com", "type": "A", "value": "172.217.192.113", "ttl": "35"}
{"domain": "github.com", "type": "A", "value": "140.82.112.3", "ttl": "60"}
{"domain": "wikipedia.org", "type": "A", "value": "195.200.68.224", "ttl": "54"}
```
**Ejemplo de Salida de Logs (out/sprint2.log):**
```bash
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Usando archivo de dominios: config/domains.txt"}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Usando servidor DNS: 8.8.8.8"}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Procesando dominio: google.com"}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Resolución A para google.com exitosa en intento 1."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.101 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.101 en el puerto 443."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.138 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.138 en el puerto 443."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.100 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.100 en el puerto 443."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.102 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.102 en el puerto 443."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.139 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.139 en el puerto 443."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.113 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Conectividad exitosa con 172.217.192.113 en el puerto 443."}
{"timestamp": "2025-09-30 12:31:47", "level": "INFO", "message": "Procesando dominio: github.com"}
{"timestamp": "2025-09-30 12:31:48", "level": "INFO", "message": "Resolución A para github.com exitosa en intento 1."}
{"timestamp": "2025-09-30 12:31:48", "level": "INFO", "message": "Conectividad exitosa con 140.82.112.3 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:48", "level": "INFO", "message": "Conectividad exitosa con 140.82.112.3 en el puerto 443."}
{"timestamp": "2025-09-30 12:31:48", "level": "INFO", "message": "Procesando dominio: wikipedia.org"}
{"timestamp": "2025-09-30 12:31:48", "level": "INFO", "message": "Resolución A para wikipedia.org exitosa en intento 1."}
{"timestamp": "2025-09-30 12:31:48", "level": "INFO", "message": "Conectividad exitosa con 195.200.68.224 en el puerto 80."}
{"timestamp": "2025-09-30 12:31:49", "level": "INFO", "message": "Conectividad exitosa con 195.200.68.224 en el puerto 443."}
```
## 4. Decisiones Técnicas
Se decidió enviar los logs a `stderr` para mantener los archivos de datos (`stdout`) completamente limpios y puros, facilitando su procesamiento por otras herramientas.
Se eligió `nc -zv` para la verificación de puertos por ser una herramienta no interactiva, rápida y estándar en sistemas Unix.