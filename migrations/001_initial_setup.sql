-- Migration 001: Crear base de datos y configuración inicial
-- Fecha: 2025-07-13
-- Descripción: Configuración inicial de PostgreSQL para Shaiya Server

-- Crear extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Configurar timezone
SET timezone = 'America/Argentina/Buenos_Aires';

-- Crear usuario de aplicación si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'shaiya_app') THEN
        CREATE ROLE shaiya_app WITH LOGIN PASSWORD 'shaiya_app_2025';
    END IF;
END
$$;

-- Comentarios de migración
COMMENT ON DATABASE shaiya_game IS 'Base de datos principal del servidor Shaiya - Migrado desde SQL Server';
