# 🎮 Shaiya PostgreSQL Database

Implementación completa de la base de datos PostgreSQL para el servidor Shaiya con sistema de migraciones automatizadas.

## 🚀 Inicio Rápido

```bash
# 1. Clonar repositorio
git clone https://github.com/Nahuelnm/shaiya_postgres_db.git
cd shaiya_postgres_db

# 2. Iniciar PostgreSQL
./shaiya.sh start

# 3. Ejecutar migraciones
./shaiya.sh migrate

# 4. Verificar estado
./shaiya.sh status
```

## 📋 Características

### ✅ Sistema de Migraciones
- **Migraciones numeradas** (001, 002, 003...)
- **Control de versiones** automático con checksums
- **Rollback seguro** y auditoría completa
- **Logs detallados** para debugging

### ✅ Base de Datos
- **PostgreSQL 15-alpine** optimizado
- **10 esquemas** organizados por funcionalidad
- **Índices optimizados** para rendimiento
- **Triggers de auditoría** automáticos

### ✅ Herramientas de Gestión
- **Script unificado** `./shaiya.sh` para todas las operaciones
- **PgAdmin web** para administración visual
- **Backup/restore** automatizado
- **Docker Compose** para deployment

## 🗄️ Esquemas de Base de Datos

| Esquema | Descripción | Estado |
|---------|-------------|--------|
| `ps_userdata` | Datos de usuarios del juego | ✅ Implementado |
| `omg_gameweb` | Datos de la web del juego | 🔄 Preparado |
| `ps_gamedata` | Datos principales del juego | 🔄 Preparado |
| `ps_gamedefs` | Definiciones y configuraciones | 🔄 Preparado |
| `ps_billing` | Sistema de facturación | 🔄 Preparado |
| `ps_chatlog` | Logs de chat | 🔄 Preparado |
| `ps_gamelog` | Logs de eventos del juego | 🔄 Preparado |
| `ps_gmtool` | Herramientas de Game Master | 🔄 Preparado |
| `ps_statdata` | Datos estadísticos | 🔄 Preparado |
| `ps_statics` | Estadísticas del juego | 🔄 Preparado |

## 📊 Datos Actuales

### Tablas Implementadas
- `ps_userdata.users_master` - Tabla principal de usuarios
- `ps_userdata.users_detail` - Detalles adicionales de usuarios

### Datos de Ejemplo
- **3 usuarios** migrados desde SQL Server original
- **Estructura completa** con constraints e índices
- **Triggers de auditoría** configurados

## 🐳 Configuración Docker

### Servicios Disponibles

#### PostgreSQL
- **Puerto**: 5432
- **Usuario**: shaiya
- **Contraseña**: shaiya123
- **Base de datos**: shaiya_game

#### PgAdmin (Opcional)
- **Puerto**: 8080
- **URL**: http://localhost:8080
- **Usuario**: admin@shaiya.local
- **Contraseña**: admin123

## 📝 Comandos Principales

### Gestión de Servicios
```bash
./shaiya.sh start              # Iniciar PostgreSQL
./shaiya.sh start-admin        # Iniciar PostgreSQL + PgAdmin
./shaiya.sh stop               # Parar servicios
./shaiya.sh restart            # Reiniciar servicios
./shaiya.sh status             # Ver estado
./shaiya.sh logs               # Ver logs
```

### Migraciones
```bash
./shaiya.sh migrate            # Ejecutar migraciones pendientes
./shaiya.sh migration-status   # Ver estado de migraciones
```

### Base de Datos
```bash
./shaiya.sh psql               # Conectar a PostgreSQL
./shaiya.sh backup             # Crear backup
./shaiya.sh dump               # Crear dump completo
./shaiya.sh restore backup.sql # Restaurar desde backup
```

## 📁 Estructura del Proyecto

```
shaiya_postgres_db/
├── README.md                   # Este archivo
├── shaiya.sh                   # Script principal de gestión
├── docker-compose.yml          # Configuración Docker
├── migrate.sh                  # Script de migraciones
├── migrations/                 # Migraciones numeradas
│   ├── 001_initial_setup.sql
│   ├── 002_create_schemas.sql
│   ├── 003_create_users_master.sql
│   ├── 004_create_users_detail.sql
│   └── 005_insert_initial_users.sql
├── dumps/                      # Backups de base de datos
│   ├── shaiya_full_dump_20250713.sql
│   └── shaiya_schema_dump_20250713.sql
└── docker/                     # Configuración Docker específica
    └── docker-compose.yml
```

## 🔧 Desarrollo

### Crear Nueva Migración
```bash
# 1. Crear archivo numerado
touch migrations/006_nueva_funcionalidad.sql

# 2. Agregar contenido
cat > migrations/006_nueva_funcionalidad.sql << 'EOF'
-- Migration 006: Nueva funcionalidad
-- Fecha: 2025-07-13
-- Descripción: Descripción de los cambios

CREATE TABLE ps_gamedata.nueva_tabla (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE ps_gamedata.nueva_tabla IS 'Descripción de la tabla';
GRANT SELECT, INSERT, UPDATE, DELETE ON ps_gamedata.nueva_tabla TO shaiya_app;
