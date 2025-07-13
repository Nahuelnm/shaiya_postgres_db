#!/bin/bash

# =============================================================================
# SCRIPT DE MIGRACIONES PARA SHAIYA POSTGRESQL
# Maneja la ejecución de migraciones numeradas
# =============================================================================

set -e

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"
DOCKER_DIR="$SCRIPT_DIR/docker"
LOG_FILE="$SCRIPT_DIR/migration.log"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función de logging
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE"
            ;;
    esac
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Función para verificar PostgreSQL
check_postgres() {
    log "INFO" "Verificando conexión a PostgreSQL..."
    
    if docker exec shaiya_postgres psql -U shaiya -d shaiya_game -c "SELECT 1;" &>/dev/null; then
        log "INFO" "✅ PostgreSQL está disponible"
        return 0
    else
        log "ERROR" "❌ PostgreSQL no está disponible"
        return 1
    fi
}

# Función para crear tabla de migraciones
create_migrations_table() {
    log "INFO" "Creando tabla de control de migraciones..."
    
    docker exec shaiya_postgres psql -U shaiya -d shaiya_game -c "
    CREATE TABLE IF NOT EXISTS public.schema_migrations (
        version VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        filename VARCHAR(255) NOT NULL,
        checksum VARCHAR(64)
    );
    
    COMMENT ON TABLE public.schema_migrations IS 'Control de versiones de migraciones aplicadas';
    " &>/dev/null
    
    log "INFO" "✅ Tabla schema_migrations lista"
}

# Función para obtener migraciones aplicadas
get_applied_migrations() {
    docker exec shaiya_postgres psql -U shaiya -d shaiya_game -t -c "
    SELECT version FROM public.schema_migrations ORDER BY version;
    " 2>/dev/null | tr -d ' ' | grep -v '^$' || echo ""
}

# Función para calcular checksum de archivo
calculate_checksum() {
    local file=$1
    sha256sum "$file" | cut -d' ' -f1
}

# Función para aplicar una migración
apply_migration() {
    local migration_file=$1
    local version=$(basename "$migration_file" .sql)
    local checksum=$(calculate_checksum "$migration_file")
    
    log "INFO" "Aplicando migración: $version"
    
    # Ejecutar migración
    if docker exec -i shaiya_postgres psql -U shaiya -d shaiya_game < "$migration_file"; then
        # Registrar migración aplicada
        docker exec shaiya_postgres psql -U shaiya -d shaiya_game -c "
        INSERT INTO public.schema_migrations (version, filename, checksum) 
        VALUES ('$version', '$(basename "$migration_file")', '$checksum');
        " &>/dev/null
        
        log "INFO" "✅ Migración $version aplicada exitosamente"
        return 0
    else
        log "ERROR" "❌ Error aplicando migración $version"
        return 1
    fi
}

# Función para ejecutar migraciones pendientes
run_migrations() {
    log "INFO" "🚀 Iniciando proceso de migraciones..."
    
    # Verificar PostgreSQL
    if ! check_postgres; then
        log "ERROR" "PostgreSQL no está disponible. Iniciando contenedor..."
        cd "$DOCKER_DIR" && docker-compose up -d postgres
        sleep 10
        
        if ! check_postgres; then
            log "ERROR" "No se pudo conectar a PostgreSQL"
            exit 1
        fi
    fi
    
    # Crear tabla de control
    create_migrations_table
    
    # Obtener migraciones aplicadas
    applied_migrations=$(get_applied_migrations)
    
    # Buscar archivos de migración
    migration_files=($(find "$MIGRATIONS_DIR" -name "*.sql" | sort))
    
    if [ ${#migration_files[@]} -eq 0 ]; then
        log "WARN" "No se encontraron archivos de migración"
        return 0
    fi
    
    log "INFO" "Encontradas ${#migration_files[@]} migraciones"
    
    # Aplicar migraciones pendientes
    local applied_count=0
    
    for migration_file in "${migration_files[@]}"; do
        local version=$(basename "$migration_file" .sql)
        
        # Verificar si ya está aplicada
        if echo "$applied_migrations" | grep -q "^$version$"; then
            log "DEBUG" "⏭️  Migración $version ya aplicada"
            continue
        fi
        
        # Aplicar migración
        if apply_migration "$migration_file"; then
            ((applied_count++))
        else
            log "ERROR" "Error en migración $version, deteniendo proceso"
            exit 1
        fi
    done
    
    if [ $applied_count -eq 0 ]; then
        log "INFO" "✅ Todas las migraciones ya están aplicadas"
    else
        log "INFO" "✅ $applied_count migraciones aplicadas exitosamente"
    fi
}

# Función para mostrar estado
show_status() {
    log "INFO" "📊 Estado de migraciones:"
    
    if ! check_postgres; then
        log "ERROR" "PostgreSQL no está disponible"
        return 1
    fi
    
    create_migrations_table
    
    echo
    echo "=== MIGRACIONES APLICADAS ==="
    docker exec shaiya_postgres psql -U shaiya -d shaiya_game -c "
    SELECT 
        version,
        filename,
        applied_at,
        LEFT(checksum, 8) || '...' as checksum_short
    FROM public.schema_migrations 
    ORDER BY version;
    "
    
    echo
    echo "=== ARCHIVOS DE MIGRACIÓN DISPONIBLES ==="
    find "$MIGRATIONS_DIR" -name "*.sql" | sort | while read -r file; do
        version=$(basename "$file" .sql)
        if docker exec shaiya_postgres psql -U shaiya -d shaiya_game -t -c "SELECT 1 FROM public.schema_migrations WHERE version = '$version';" 2>/dev/null | grep -q "1"; then
            echo "✅ $version (aplicada)"
        else
            echo "⏳ $version (pendiente)"
        fi
    done
}

# Función para crear backup antes de migraciones
create_backup() {
    local backup_dir="$SCRIPT_DIR/dumps"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/backup_pre_migration_$timestamp.sql"
    
    mkdir -p "$backup_dir"
    
    log "INFO" "Creando backup pre-migración..."
    
    if docker exec shaiya_postgres pg_dump -U shaiya -d shaiya_game > "$backup_file"; then
        log "INFO" "✅ Backup creado: $backup_file"
    else
        log "ERROR" "❌ Error creando backup"
        return 1
    fi
}

# Función principal
main() {
    case "${1:-run}" in
        "run"|"migrate")
            run_migrations
            ;;
        "status")
            show_status
            ;;
        "backup")
            create_backup
            ;;
        "reset")
            log "WARN" "⚠️ Reiniciando tabla de migraciones..."
            docker exec shaiya_postgres psql -U shaiya -d shaiya_game -c "DROP TABLE IF EXISTS public.schema_migrations;" &>/dev/null
            log "INFO" "✅ Tabla de migraciones reiniciada"
            ;;
        "help"|"-h"|"--help")
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  run|migrate  - Ejecutar migraciones pendientes (por defecto)"
            echo "  status       - Mostrar estado de migraciones"
            echo "  backup       - Crear backup de la base de datos"
            echo "  reset        - Reiniciar tabla de control de migraciones"
            echo "  help         - Mostrar esta ayuda"
            ;;
        *)
            log "ERROR" "Comando desconocido: $1"
            echo "Usa '$0 help' para ver comandos disponibles"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
