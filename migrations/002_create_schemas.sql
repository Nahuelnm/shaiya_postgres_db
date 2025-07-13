-- Migration 002: Crear esquemas de base de datos
-- Fecha: 2025-07-13
-- Descripción: Creación de todos los esquemas necesarios para Shaiya

-- Esquema para datos de usuarios
CREATE SCHEMA IF NOT EXISTS ps_userdata;
COMMENT ON SCHEMA ps_userdata IS 'Datos de usuarios del juego';

-- Esquema para datos del juego web
CREATE SCHEMA IF NOT EXISTS omg_gameweb;
COMMENT ON SCHEMA omg_gameweb IS 'Datos de la web del juego';

-- Esquema para datos principales del juego
CREATE SCHEMA IF NOT EXISTS ps_gamedata;
COMMENT ON SCHEMA ps_gamedata IS 'Datos principales del juego';

-- Esquema para definiciones del juego
CREATE SCHEMA IF NOT EXISTS ps_gamedefs;
COMMENT ON SCHEMA ps_gamedefs IS 'Definiciones y configuraciones del juego';

-- Esquema para facturación
CREATE SCHEMA IF NOT EXISTS ps_billing;
COMMENT ON SCHEMA ps_billing IS 'Sistema de facturación y pagos';

-- Esquema para logs de chat
CREATE SCHEMA IF NOT EXISTS ps_chatlog;
COMMENT ON SCHEMA ps_chatlog IS 'Logs de chat del juego';

-- Esquema para logs del juego
CREATE SCHEMA IF NOT EXISTS ps_gamelog;
COMMENT ON SCHEMA ps_gamelog IS 'Logs de eventos del juego';

-- Esquema para herramientas de GM
CREATE SCHEMA IF NOT EXISTS ps_gmtool;
COMMENT ON SCHEMA ps_gmtool IS 'Herramientas de Game Master';

-- Esquema para datos estadísticos
CREATE SCHEMA IF NOT EXISTS ps_statdata;
COMMENT ON SCHEMA ps_statdata IS 'Datos estadísticos del juego';

-- Esquema para estadísticas
CREATE SCHEMA IF NOT EXISTS ps_statics;
COMMENT ON SCHEMA ps_statics IS 'Estadísticas del juego';

-- Otorgar permisos básicos al usuario de aplicación
GRANT USAGE ON SCHEMA ps_userdata TO shaiya_app;
GRANT USAGE ON SCHEMA omg_gameweb TO shaiya_app;
GRANT USAGE ON SCHEMA ps_gamedata TO shaiya_app;
GRANT USAGE ON SCHEMA ps_gamedefs TO shaiya_app;
GRANT USAGE ON SCHEMA ps_billing TO shaiya_app;
GRANT USAGE ON SCHEMA ps_chatlog TO shaiya_app;
GRANT USAGE ON SCHEMA ps_gamelog TO shaiya_app;
GRANT USAGE ON SCHEMA ps_gmtool TO shaiya_app;
GRANT USAGE ON SCHEMA ps_statdata TO shaiya_app;
GRANT USAGE ON SCHEMA ps_statics TO shaiya_app;
