# Makefile inicial
.PHONY: help tools build test run package dist-clean
#VARIABLES
TOOLS = dig curl ss nc bats
INSTALA = sudo apt-get install -y

DOMAINS_FILE ?= config/domains.txt
DNS_SERVER   ?= 8.8.8.8
DIST_DIR     = dist
PKG_NAME     = proyecto
PKG_VERSION  = 1.0.0
PKG_FILE     = $(DIST_DIR)/$(PKG_NAME)-$(PKG_VERSION).tar.gz

help: ## Mostrar los targets disponibles
	@echo "Make targets:"
	@grep -E '^[a-zA-Z0-9_\-]+:.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

tools: ## Verificar e instalar herramientas necesarias
	@echo "Verificando herramientas necesarias..."
	@$(foreach tool,$(TOOLS),\
		if ! command -v $(tool) >/dev/null 2>&1; then \
			echo "[FALTA] $(tool) no está instalado. Instalando..."; \
			$(INSTALA) $(tool); \
		else \
			echo "[OK] $(tool) ya está instalado"; \
		fi;\
	)
	@echo "Todas las herramientas verificadas."

build: ## Construir el proyecto
	@echo "Dando permisos de ejecución..."
	@chmod +x ./tests/test_analizar_grafo.bats
	@chmod +x ./src/analizar-grafo.sh
	@chmod +x ./src/resolve.sh
	@echo "Permisos dados."

test: ## Ejecutar pruebas
	@echo "Ejecutando pruebas..."
	@./tests/test_analizar_grafo.bats

run: ## Ejecutar la aplicación
	@echo "Ejecutando la aplicación..."
	@echo "  DOMAINS_FILE=$(DOMAINS_FILE)"
	@echo "  DNS_SERVER=$(DNS_SERVER)"
	@DOMAINS_FILE="$(DOMAINS_FILE)" DNS_SERVER="$(DNS_SERVER)" ./src/resolve.sh > out/dns-resolved.json 2> out/sprint2.log
	@DOMAINS_FILE="$(DOMAINS_FILE)" DNS_SERVER="$(DNS_SERVER)" ./src/analizar-grafo.sh
	

clean: ## Limpiar archivos
	@echo "Limpiando archivos generados..."
	@rm out/dns-resolved.json
	@rm out/edge-list.txt
	@rm out/preview.grafo.dot
	
package: $(PKG_FILE) ## Crear paquete reproducible en dist/

$(PKG_FILE): build | $(DIST_DIR)
	@echo "Creando paquete reproducible: $@"
	@tar --sort=name \
	     --owner=0 --group=0 --numeric-owner \
	     --mtime="UTC 2020-01-01" \
	     -czf $@ \
	     config src tests README.md Makefile

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

dist-clean: ## Limpiar paquetes en dist/
	@echo "Limpiando dist/"
	@rm -rf $(DIST_DIR)