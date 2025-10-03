# Bitácora Sprint 3 - Rama: feature/automation-Serrano-Max

**Responsable:** Max Serrano
**Fecha:** 2 de octubre de 2025

# Objetivos
Se verificacaron los siguientes conceptos:
Reproducibilidad al garantizar que cualquier build y empaquetado sea igual en cualquier máquina.
Configurabilidad al permitir que DOMAINS_FILE y DNS_SERVER se pasen como parámetros externos.
Documentación formal al contar con un README.md con contratos claros de entrada, salida y comportamiento esperado.
Pipeline ejecutable al asegurar que resolve.sh y analizar-grafo.sh funcionen en conjunto mediante make run.

# Cambios:

Makefile:

    Se añadió empaquetado reproducible (make package) con exclusión de docs/.
    Se parametrizaron DOMAINS_FILE y DNS_SERVER.

Se verificaron targets como build, run, test, clean... los cuales estan definidos con contratos claros.

Documentación:

    Se generó README.md con contratos para resolve.sh, analizar-grafo.sh y el Makefile.

Estructura de proyecto:

    config/, src/, tests/, out/, dist/.
Se verificaron los scripts con permisos y pruebas automatizadas (bats).

# Ejecuciones
Flujo principal:

make help:

```bash
Make targets:
  help                    Mostrar los targets disponibles
  tools                   Verificar e instalar herramientas necesarias
  build                   Construir el proyecto
  test                    Ejecutar pruebas
  run                     Ejecutar la aplicación
  clean                   Limpiar archivos
  package                 Crear paquete reproducible en dist/
  dist-clean              Limpiar paquetes en dist/
```

make tools:

```bash
Verificando herramientas necesarias...
[OK] dig ya está instalado
[OK] curl ya está instalado
[OK] ss ya está instalado
[OK] nc ya está instalado
[OK] bats ya está instalado
Todas las herramientas verificadas.
```

make build:

```bash
Dando permisos de ejecución...
Permisos dados.
```
make test:

```bash
Ejecutando pruebas...
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

make run:

```bash
{"timestamp": "2025-10-02 21:17:14", "level": "INFO", "message": "Conectividad exitosa con 195.200.68.224 en el puerto 443."}
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

make clean:

```bash
Limpiando archivos generados...
```

make package:

```bash
Dando permisos de ejecución...
Permisos dados.
Creando paquete reproducible: dist/proyecto-1.0.0.tar.gz
```

make dist-clean:

```bash
Limpiando dist/
```