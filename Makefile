# Makefile inicial
.PHONY: help tools build test run
#VARIABLES
TOOLS = dig curl ss nc bats
INSTALA = sudo apt-get install -y

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
	@chmod +x ./tests/test_parse_csv.bats
	@echo "Permisos dados."

test: ## Ejecutar pruebas
	@echo "Ejecutando pruebas..."
	@./tests/test_parse_csv.bats

run: ## Ejecutar la aplicación
	@echo "Ejecutando la aplicación..."

clean: ## Limpiar archivos
	@echo "Limpiando archivos generados..."
	
