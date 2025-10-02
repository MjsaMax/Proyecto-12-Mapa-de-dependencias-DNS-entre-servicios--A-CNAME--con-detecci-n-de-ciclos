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

---
# Bitácora Sprint 2 - Rama: feature/grafo-dns

**responsable:** Poma Navarro, Walter Bryan
**Fecha:** 30 de septiembre de 2025

## 1. Objetivo del Sprint

El objetivo del sprint2 para la rama de grafo-dns fue evolucionar el script del sprint1 para que, además de procesar los datos, pudiera realizar un análisis estructural del grafo de dependencias DNS. Las metas principales fueron implementar la detección de ciclos de CNAMEs, calcular la profundidad máxima de las cadenas de resolución y exportar estas métricas.

## 2. Cambios y Nuevas Funcionalidades

El cambio más grande que hicimos fue la adapta el script al nuevo formato de entrada JSON, que reemplazó al CSV.

* Se refactorizaron las funciones de validación y procesamiento para usar la herramienta `jq` para parsear cada línea.

* Las validaciones ahora comprueban la presencia de claves (`has("key")`) y el tipo de dato (`test("regex")`) en lugar de contar columnas.

Se optimizó el script para leer el archivo de entrada una sola vez. Ya con esta lectura se construye el grafo en memoria utilizando un array asociativo de Bash, lo que permite un análisis posterior mucho más eficiente.

Añadí la función `analizar_grafo`, que implementa el algoritmo de DFS para cumplir con los requisitos de análisis:
* Detección de Ciclos:El algoritmo recorre cada cadena de dependencias y mantiene un registro de la "ruta actual". Si un nodo se vuelve a encontrar en su propia ruta, se reporta un ciclo.
* Cálculo de Profundidad Máxima: Durante el recorrido de cada cadena, se cuenta el número de "saltos".

Se creó la función `imprime_metricas` para mostrar en la consola un resumen con los resultados del análisis.

Se modificó las pruebas bats para que estén de acuerdo al formato JSON.

## 3. Comandos y Evidencias

### 3.1. Ejecución del Flujo Completo
```bash
# 1. Ejecutar el script de resolve-dns
export DOMAINS_FILE="config/domains.txt"
export DNS_SERVER="8.8.8.8"
./src/resolve.sh > out/dns-resolved.json 2> out/sprint2.log

# 2. Ejecutar mi script de análisis
./src/analizar-grafo.sh
```

Salida:
```bash
Iniciando el script para analizar el JSON de DNS
--- Iniciando Fase de Validación y Construcción del Grafo ---
Validación y construcción del grafo OK.
--- Iniciando Fase de Análisis del Grafo ---
--- Iniciando fase de generación de grafo ---
Generando archivo de visualización en 'out/preview.grafo.dot'...
--- Exportando Métricas del Análisis ---
Número de nodos: 3
Ciclos detectados: 0
Profundidad máxima: 1
Proceso completado. El resultado está en 'out/edge-list.txt'.
```

### 3.2. Ejecución de las pruebas bats
```bash
# 1. Ejecutar pruebas bats
bats ./tests/test_analizar_grafo.bats 
```

Salida:
```bash
 ✓ Debe procesar un JSON válido y generar un edge-list correcto + DOT
 ✓ Debe abortar con código de error 1 si el JSON tiene TTL no numérico
 ✓ Debe abortar con código de error 1 si falta un campo (por ejemplo TTL vacío)

3 tests, 0 failures
```

---

# Bitácora Sprint 2 - Rama: feature/automation-Serrano-Max

**Responsable:** Max Serrano
**Fecha:** 1 de octubre de 2025

# Objetivos
En este sprint lo que se realizó por mi parte fue agregar robustez al test usando bats,
se generan [CASO-POSITIVO] ,2 [CASO-NEGATIVO], un [CASO-TIMEOUT] y 2 [METRICA].
Se agrego al script analizar-grafo.sh una salida de trap con se señales SIGTERM, SIGINT y SIGQUIT.

# Cambios:

- [CASO-POSITIVO] resolve.sh resuelve dominios reales y genera JSON válido
- [CASO-NEGATIVO] resolve.sh maneja NXDOMAIN sin crashear
- [CASO-NEGATIVO] Conectividad falla correctamente en puertos cerrados
- [CASO-TIMEOUT] analizar-grafo.sh detecta ciclos sin loop infinito
- [METRICA] Falla si se detectan ciclos (threshold: ciclos > 0)
- [METRICA] Pasa si NO hay ciclos (threshold: ciclos == 0)

Se agrego trap en analizar-grafo.sh:

```
# Limpia 
cleanup() {
  echo "[INTERRUPCION] Interrupcion detectada. Limpiando..."
  rm -f "$OUTPUT_FILE" "$GRAFO_OUTPUT" 2>/dev/null || true
  exit 0
}
#Detecta señales de interrupcion {SIGINT SIGTERM SIGQUIT} y ejecuta cleanup
trap cleanup SIGINT SIGTERM SIGQUIT
```
# Ejecuciones

bats:
```bash
ax--@PP:~/Proyectos/Proyecto-13-Evaluador-de-resiliencia-de-endpoints-con-reintentos-y-jitter-controlado$ bats tests/test_analizar_grafo.bats 
test_analizar_grafo.bats
 ✓ Debe procesar un JSON válido y generar un edge-list correcto + DOT
 ✓ Debe abortar con código de error 1 si el JSON tiene TTL no numérico
 ✓ Debe abortar con código de error 1 si falta un campo (por ejemplo TTL vacío)
 ✓ [CASO-POSITIVO] resolve.sh resuelve dominios reales y genera JSON válido
 ✓ [CASO-NEGATIVO] resolve.sh maneja NXDOMAIN sin crashear
 ✓ [CASO-NEGATIVO] Conectividad falla correctamente en puertos cerrados
 ✓ [CASO-TIMEOUT] analizar-grafo.sh detecta ciclos sin loop infinito
 ✓ [METRICA] Falla si se detectan ciclos (threshold: ciclos > 0)
 ✓ [METRICA] Pasa si NO hay ciclos (threshold: ciclos == 0)

9 tests, 0 failures
```
analizar-grafo.sh:

Interrupción por `Ctrl + C`:

```bash
ax--@PP:~/Proyectos/Proyecto-13-Evaluador-de-resiliencia-de-endpoints-con-reintentos-y-jitter-controlado$ ./src/analizar-grafo.sh 
Iniciando el script para analizar el JSON de DNS
--- Iniciando Fase de Validación y Construcción del Grafo ---
^C[INTERRUPCION] Interrupcion detectada. Limpiando...
```