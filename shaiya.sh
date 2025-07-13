#!/bin/bash

# =============================================================================
# SCRIPT DE GESTIÓN DE SHAIYA SERVER
# Script principal para manejar base de datos, migraciones y servicios
# =============================================================================

set -e

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"

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
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac
}

# Función para mostrar ayuda
show_help() {
    cat << EOF
🎮 Shaiya Server - Script de Gestión

SERVICIOS:
  start              - Iniciar PostgreSQL
  start-admin        - Iniciar PostgreSQL + PgAdmin
  stop               - Parar todos los servicios
  restart            - Reiniciar servicios
  status             - Ver estado de contenedores
  logs               - Ver logs de PostgreSQL

MIGRACIONES:
  migrate            - Ejecutar migraciones pendientes
  migration-status   - Ver estado de migraciones
  backup             - Crear backup de la base de datos
  restore <archivo>  - Restaurar desde backup

BASE DE DATOS:
  psql               - Conectar a PostgreSQL
  dump               - Crear dump completo
  dump-schema        - Crear dump solo del esquema

DESARROLLO:
  clean              - Limpiar volúmenes (¡CUIDADO!)
  reset              - Reset completo (¡CUIDADO!)

AYUDA:
  help               - Mostrar esta ayuda

Ejemplos:
  $0 start
  $0 migrate
  $0 psql
  $0 backup
  $0 restore backup_20250713.sql

EOF
}

# Función para verificar Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker no está instalado"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log "ERROR" "Docker Compose no está instalado"
        exit 1
    fi
}

# Funciones de servicios
start_services() {
    log "INFO" "🚀 Iniciando PostgreSQL..."
    docker-compose up -d postgres
    
    log "INFO" "⏳ Esperando que PostgreSQL esté listo..."
    sleep 5
    
    if docker exec shaiya_postgres pg_isready -U shaiya -d shaiya_game &>/dev/null; then
        log "INFO" "✅ PostgreSQL está listo"
    else
        log "WARN" "⚠️ PostgreSQL aún no está listo, puede tomar unos momentos más"
    fi
}

start_admin() {
    log "INFO" "🚀 Iniciando PostgreSQL + PgAdmin..."
    docker-compose --profile admin up -d
    
    log "INFO" "⏳ Esperando que los servicios estén listos..."
    sleep 10
    
    log "INFO" "✅ Servicios iniciados:"
    log "INFO" "  📊 PostgreSQL: localhost:5432"
    log "INFO" "  🌐 PgAdmin: http://localhost:8080"
    log "INFO" "     Usuario: admin@shaiya.local"
    log "INFO" "     Contraseña: admin123"
}

stop_services() {
    log "INFO" "🛑 Parando servicios..."
    docker-compose down
    log "INFO" "✅ Servicios parados"
}

restart_services() {
    stop_services
    sleep 2
    start_services
}

show_status() {
    log "INFO" "📊 Estado de contenedores:"
    docker-compose ps
    
    echo
    log "INFO" "🗄️ Estado de PostgreSQL:"
    if docker exec shaiya_postgres pg_isready -U shaiya -d shaiya_game &>/dev/null; then
        log "INFO" "✅ PostgreSQL está activo y acepta conexiones"
        
        # Mostrar información adicional
        echo
        docker exec shaiya_postgres psql -U shaiya -d shaiya_game -c "
        SELECT 
            'Usuarios registrados' as metric,
            COUNT(*) as value
        FROM ps_userdata.users_master
        UNION ALL
        SELECT 
            'Esquemas creados' as metric,
            COUNT(*) as value
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast_temp_1', 'pg_temp_1', 'public');
        " 2>/dev/null || echo "No hay datos disponibles aún"
    else
        log "ERROR" "❌ PostgreSQL no está disponible"
    fi
}

show_logs() {
    log "INFO" "📝 Logs de PostgreSQL (presiona Ctrl+C para salir):"
    docker-compose logs -f postgres
}

# Funciones de migraciones
run_migrations() {
    log "INFO" "🔄 Ejecutando migraciones..."
    cd "$MIGRATIONS_DIR"
    ./migrate.sh
    cd "$SCRIPT_DIR"
}

migration_status() {
    log "INFO" "📊 Estado de migraciones:"
    cd "$MIGRATIONS_DIR"
    ./migrate.sh status
    cd "$SCRIPT_DIR"
}

# Funciones de backup/restore
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="backup_shaiya_$timestamp.sql"
    
    log "INFO" "💾 Creando backup..."
    
    if docker exec shaiya_postgres pg_dump -U shaiya -d shaiya_game > "$backup_file"; then
        log "INFO" "✅ Backup creado: $backup_file"
        log "INFO" "📊 Tamaño: $(du -h "$backup_file" | cut -f1)"
    else
        log "ERROR" "❌ Error creando backup"
        return 1
    fi
}

restore_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        log "ERROR" "Debe especificar un archivo de backup"
        echo "Uso: $0 restore archivo_backup.sql"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "Archivo de backup no encontrado: $backup_file"
        return 1
    fi
    
    log "WARN" "⚠️ Esta operación sobrescribirá la base de datos actual"
    read -p "¿Está seguro? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "🔄 Restaurando desde $backup_file..."
        
        # Crear backup antes de restaurar
        create_backup
        
        # Restaurar
        if cat "$backup_file" | docker exec -i shaiya_postgres psql -U shaiya -d shaiya_game; then
            log "INFO" "✅ Backup restaurado exitosamente"
        else
            log "ERROR" "❌ Error restaurando backup"
            return 1
        fi
    else
        log "INFO" "Operación cancelada"
    fi
}

# Funciones de base de datos
connect_psql() {
    log "INFO" "🔗 Conectando a PostgreSQL..."
    log "INFO" "💡 Tip: Usar \\q para salir"
    docker exec -it shaiya_postgres psql -U shaiya -d shaiya_game
}

create_dump() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local dump_file="dump_shaiya_$timestamp.sql"
    
    log "INFO" "💾 Creando dump completo..."
    
    if docker exec shaiya_postgres pg_dump -U shaiya -d shaiya_game > "$dump_file"; then
        log "INFO" "✅ Dump creado: $dump_file"
        log "INFO" "📊 Tamaño: $(du -h "$dump_file" | cut -f1)"
    else
        log "ERROR" "❌ Error creando dump"
        return 1
    fi
}

create_schema_dump() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local dump_file="schema_shaiya_$timestamp.sql"
    
    log "INFO" "💾 Creando dump del esquema..."
    
    if docker exec shaiya_postgres pg_dump -U shaiya -d shaiya_game --schema-only > "$dump_file"; then
        log "INFO" "✅ Dump del esquema creado: $dump_file"
        log "INFO" "📊 Tamaño: $(du -h "$dump_file" | cut -f1)"
    else
        log "ERROR" "❌ Error creando dump del esquema"
        return 1
    fi
}

# Funciones de desarrollo
clean_volumes() {
    log "WARN" "⚠️ Esta operación eliminará TODOS los datos de la base de datos"
    log "WARN" "⚠️ Esta acción NO se puede deshacer"
    read -p "¿Está ABSOLUTAMENTE seguro? (escriba 'DELETE' para confirmar): " -r
    echo
    
    if [[ $REPLY == "DELETE" ]]; then
        log "INFO" "🧹 Limpiando volúmenes..."
        docker-compose down -v
        docker volume prune -f
        log "INFO" "✅ Volúmenes eliminados"
    else
        log "INFO" "Operación cancelada"
    fi
}

reset_all() {
    log "WARN" "⚠️ Esta operación hará un reset COMPLETO del sistema"
    log "WARN" "⚠️ Se eliminarán todos los datos y configuraciones"
    read -p "¿Está ABSOLUTAMENTE seguro? (escriba 'RESET' para confirmar): " -r
    echo
    
    if [[ $REPLY == "RESET" ]]; then
        log "INFO" "🔄 Reset completo del sistema..."
        
        # Parar y limpiar todo
        docker-compose down -v
        docker volume prune -f
        
        # Reiniciar
        start_services
        sleep 10
        
        # Ejecutar migraciones
        run_migrations
        
        log "INFO" "✅ Reset completo finalizado"
    else
        log "INFO" "Operación cancelada"
    fi
}

# Función principal
main() {
    check_docker
    
    case "${1:-help}" in
        "start")
            start_services
            ;;
        "start-admin")
            start_admin
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "migrate")
            run_migrations
            ;;
        "migration-status")
            migration_status
            ;;
        "backup")
            create_backup
            ;;
        "restore")
            restore_backup "$2"
            ;;
        "psql")
            connect_psql
            ;;
        "dump")
            create_dump
            ;;
        "dump-schema")
            create_schema_dump
            ;;
        "clean")
            clean_volumes
            ;;
        "reset")
            reset_all
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log "ERROR" "Comando desconocido: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
