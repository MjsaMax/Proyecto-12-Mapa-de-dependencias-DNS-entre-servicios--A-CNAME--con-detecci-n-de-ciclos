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
```

---
# Rama: feature/grafo-dns-Poma_Walter
**Responsable:** Poma Navarro Walter Bryan
**Fecha:** 26 de septiembre de 2025

## 1. Resumen del Sprint

El objetivo de este primer sprint fue desarrollar la base para el analizador de dependencias DNS. En esta parte me centré en crear un script en Bash (`parse-csv.sh`) capaz de leer y validar un archivo CSV con registros DNS (`dns-resolved.csv`) para transformarlo en una lista de conexiones (`edge-list.txt`), que servirá para el análisis del grafo en el siguiente sprint.

## 2. Comandos y Evidencias

A continuación, se muestran los comandos clave ejecutados y las evidencias de los archivos generados.

### 2.1. Ejecución de Scripts

Se exportaron las variables de entorno necesarias y se ejecutaron los scripts en secuencia para generar los artefactos de salida.

```bash
# Exportación de variables de entorno
export DOMAINS_FILE="config/domains.txt"
export DNS_SERVER="8.8.8.8"

# Ejecución del script que resuelve los DNS
./src/resolve.sh

# Ejecución de mi script de parseo y validación
./src/parse-csv.sh
```

### 2.2. Evidencia de Salidas

Los scripts generaron los siguientes archivos en el directorio out/.

**`out/dns-resolved.csv` (Fragmento):**
```csv
github.com,A,140.82.113.4,60
google.com,A,64.233.186.100,211
google.com,A,64.233.186.101,211
```

**`out/edge-list.txt` (Fragmento):**
```
github.com 140.82.113.4
google.com 64.233.186.100
google.com 64.233.186.101
```

**`out/preview.grafo.dot` (Fragmento):**
```
digraph DNS {
"github.com" -> "140.82.113.4";
"google.com" -> "64.233.186.100";
"google.com" -> "64.233.186.101";
```

### 2.3 Pruebas Automatizadas con Bats

Para garantizar la calidad y el correcto funcionamiento del script parse-csv.sh, se implementó una suite de pruebas automatizada utilizando el framework Bats.

Se creó el archivo `tests/test_parse_csv.bats`. Cada prueba se ejecuta en un entorno limpio y aislado gracias a las funciones `setup` (que crea un directorio temporal) y `teardown` (que lo elimina al finalizar).

Los casos de prueba se diseñaron siguiendo el patrón **Arrange-Act-Assert (AAA)** para asegurar que cada prueba fuera clara y precisa en su propósito.

La suite de pruebas valida los siguientes comportamientos clave del script:
    * **Caso de Éxito:** Verifica que un archivo CSV válido es procesado correctamente, generando los artefactos de salida (`edge-list.txt`, `preview.grafo.dot`) con el contenido esperado y finalizando con un código de estado `0`.
    * **Casos de Error:** Se comprueba que el script aborta con un código de estado `1` y muestra el mensaje de error adecuado cuando la entrada es inválida (ej. un TTL no numérico o una línea con campos incompletos).

Esta implementación satisface el requisito del Sprint 1 de desarrollar una prueba Bats representativa, validando tanto el flujo de éxito como el manejo de fallos.

## 3. Decisiones Técnicas Clave

Durante el desarrollo se tomaron varias decisiones importantes para asegurar la robustez y calidad del script.

1.  **Manejo de Errores en CSV de Entrada:** Se detectó que una versión inicial del script `resolve.sh` generaba un CSV con formato anómalo (columna de destino vacía y TTL en la posición incorrecta). Se decidió aplicar una l´+ogica defensiva donde se tiene un PREVALIDACION de CSV antes de hacer conexiones.

2.  **Refactorización a Múltiples Fases:** Inicialmente, la validación y el procesamiento estaban mezclados. Se refactorizó el script para separarlos en dos funciones distintas: `validacion_csv` y `procesar_csv`. Esta estructura permite primero verificar la integridad de todo el archivo de entrada y emitir un único mensaje de "Validación OK", y solo después, si no hay errores, proceder con el procesamiento. Esto hace el código más limpio, modular y fácil de mantener.

3.  **Modularización de la Generación del Grafo:** Siguiendo las buenas prácticas, la lógica para generar el archivo `.dot` para Graphviz se extrajo a su propia función (`generar_grafo`).



---
# Rama: feature/automation-Serrano-Max
**Responsable:** Serrano Arostegui Max Jairo
**Fecha:** 28 de septiembre de 2025

# 1. Resumen del Sprint
En este Sprint se ha implementado el Makefile con los targets principales: build,run,test,help,clean,tools.
# 2. Evidencias
Ejecuciones:
```bash
make help
Make targets:
  help                    Mostrar los targets disponibles
  tools                   Verificar e instalar herramientas necesarias
  build                   Construir el proyecto
  test                    Ejecutar pruebas
  run                     Ejecutar la aplicación
  clean                   Limpiar archivos
```
```bash
make build
Dando permisos de ejecución...
Permisos dados.
```
```bash
make tools
Verificando herramientas necesarias...
[OK] dig ya está instalado
[OK] curl ya está instalado
[OK] ss ya está instalado
[OK] nc ya está instalado
[OK] bats ya está instalado
Todas las herramientas verificadas.
```
```bash
make test
Ejecutando pruebas...
test_parse_csv.bats
 ✓ Debe procesar un CSV válido y generar un edge-list correcto + DOT
 ✓ Debe abortar con código de error 1 si el CSV tiene TTL no numérico
 ✓ Debe abortar con código de error 1 si falta un campo (por ejemplo TTL vacío)

3 tests, 0 failures
```
```bash
make run
Ejecutando la aplicación...
```
```bash
make clean
Limpiando archivos generados...
```



