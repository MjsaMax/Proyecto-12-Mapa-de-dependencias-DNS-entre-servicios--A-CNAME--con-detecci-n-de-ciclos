# Proyecto 12: Mapa de dependencias DNS entre servicios (A/CNAME) con detección de ciclos

Este proyecto construye un grafo de dependencias entre dominios a partir de registros DNS tipo **A** y **CNAME**, y detecta ciclos en la resolución.  
Permite visualizar cómo un servicio depende de otros a nivel DNS y verificar si existen bucles que puedan afectar la disponibilidad.


---

## Estructura

```
├── config/              # Archivos de configuración (ej: lista de dominios)
├── src/                 # Scripts principales
│   ├── resolve.sh       # Resolver dominios con DNS configurado
│   └── analizar-grafo.sh # Analizar grafo de dependencias y detectar ciclos
├── tests/               # Pruebas automatizadas (Bats)
├── Makefile             # Automatización de tareas
└── README.md            # Documentación del proyecto
```

---

## Variables de entorno

- **`DOMAINS_FILE`**: archivo que contiene los dominios a resolver (default: `config/domains.txt`).
- **`DNS_SERVER`**: servidor DNS a utilizar (default: `8.8.8.8`).

### Ejemplo:

```bash
make run DOMAINS_FILE=config/custom.txt DNS_SERVER=1.1.1.1
```

---

## Contratos de Scripts

### `resolve.sh`

#### **Entrada:**
- `DOMAINS_FILE`: ruta a un archivo `.txt` con 1 dominio por línea.
- `DNS_SERVER`: dirección IP de un servidor DNS válido.

#### **Salida:**
- Archivo `out/dns-resolved.json` con entradas en formato JSON:

```json
{"domain": "example.com", "type": "A", "value": "93.184.216.34", "ttl": "3600"}
```

#### **Contrato:**
- Si un dominio no se resuelve, debe registrarse con `"value": null`.
- El script **no debe colgarse** si hay un timeout de resolución.
- El archivo de salida debe sobrescribirse en cada ejecución.

---

### `analizar-grafo.sh`

#### **Entrada:**
- `out/dns-resolved.json`: generado por `resolve.sh`.

#### **Salida:**
- `out/edge-list.txt` con relaciones de dependencias (`origen destino`).
- `out/preview.grafo.dot` archivo DOT para visualización.

#### **Contrato:**
- Detectar ciclos en la relación CNAME → CNAME.
- Si se encuentra un ciclo, debe reportarse en `stderr` pero seguir generando `edge-list.txt`.
- El archivo DOT debe ser válido para `graphviz`.

---

### `Makefile`

#### **Targets principales:**
- `make build` → Dar permisos de ejecución a scripts.
- `make run` → Ejecuta `resolve.sh` y `analizar-grafo.sh`.
- `make test` → Corre pruebas Bats.
- `make clean` → Limpia `out/`.

#### **Contrato:**
- Todos los targets deben ser reproducibles.
- `make run` debe aceptar parámetros externos (`DOMAINS_FILE`, `DNS_SERVER`).
- `make package` debe generar un `.tar.gz` reproducible en `dist/`.

---

## Pruebas

Ejecutar:

```bash
make test
```

### **Contrato de pruebas:**
- Debe cubrir resolución de dominios existentes y no existentes.
- Debe validar detección de ciclos en grafos pequeños.
- Las pruebas no deben depender de conectividad externa (se pueden usar mocks).

---

## Empaquetado

Crear paquete reproducible:

```bash
make package
```

El tarball incluirá:

```
config/
src/
tests/
Makefile
README.md
```
