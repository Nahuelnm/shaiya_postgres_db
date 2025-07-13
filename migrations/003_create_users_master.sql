-- Migration 003: Crear tabla users_master
-- Fecha: 2025-07-13
-- Descripción: Tabla principal de usuarios del sistema

CREATE TABLE ps_userdata.users_master (
    userid INTEGER NOT NULL,
    userno INTEGER NOT NULL,
    username VARCHAR(50) NOT NULL,
    userpw VARCHAR(50) NOT NULL,
    date1 TIMESTAMP,
    privilege INTEGER DEFAULT 0,
    status INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    warning INTEGER DEFAULT 0,
    banreason INTEGER DEFAULT 0,
    date2 TIMESTAMP,
    delcharacter CHAR(1) DEFAULT 'N',
    nation VARCHAR(20),
    grow VARCHAR(20),
    gamepoint INTEGER,
    user_ip BIGINT DEFAULT 0,
    ggauth VARCHAR(50),
    col18 VARCHAR(50),
    
    -- Timestamps de auditoría
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint principal
    CONSTRAINT users_master_pkey PRIMARY KEY (userid),
    
    -- Constraints únicos
    CONSTRAINT users_master_username_unique UNIQUE (username),
    CONSTRAINT users_master_userno_unique UNIQUE (userno),
    
    -- Constraints de validación
    CONSTRAINT users_master_privilege_check CHECK (privilege IN (0, 1, 2)),
    CONSTRAINT users_master_status_check CHECK (status >= 0),
    CONSTRAINT users_master_username_check CHECK (LENGTH(username) >= 3)
);

-- Índices para rendimiento
CREATE INDEX idx_users_master_username ON ps_userdata.users_master(username);
CREATE INDEX idx_users_master_userno ON ps_userdata.users_master(userno);
CREATE INDEX idx_users_master_status ON ps_userdata.users_master(status);
CREATE INDEX idx_users_master_privilege ON ps_userdata.users_master(privilege);
CREATE INDEX idx_users_master_date1 ON ps_userdata.users_master(date1);

-- Comentarios de documentación
COMMENT ON TABLE ps_userdata.users_master IS 'Tabla principal de usuarios del juego Shaiya';
COMMENT ON COLUMN ps_userdata.users_master.userid IS 'ID único del usuario (Primary Key)';
COMMENT ON COLUMN ps_userdata.users_master.userno IS 'Número de usuario único';
COMMENT ON COLUMN ps_userdata.users_master.username IS 'Nombre de usuario único';
COMMENT ON COLUMN ps_userdata.users_master.userpw IS 'Contraseña del usuario';
COMMENT ON COLUMN ps_userdata.users_master.date1 IS 'Fecha de registro del usuario';
COMMENT ON COLUMN ps_userdata.users_master.privilege IS 'Nivel de privilegios: 0=Usuario, 1=Admin, 2=SuperAdmin';
COMMENT ON COLUMN ps_userdata.users_master.status IS 'Estado del usuario: 0=Inactivo, 255=Activo';
COMMENT ON COLUMN ps_userdata.users_master.points IS 'Puntos del usuario';
COMMENT ON COLUMN ps_userdata.users_master.warning IS 'Número de advertencias';
COMMENT ON COLUMN ps_userdata.users_master.banreason IS 'Código de razón de ban';
COMMENT ON COLUMN ps_userdata.users_master.date2 IS 'Fecha de expiración de cuenta';
COMMENT ON COLUMN ps_userdata.users_master.delcharacter IS 'Permitir eliminación de personajes (A=Permitido, N=No permitido)';
COMMENT ON COLUMN ps_userdata.users_master.user_ip IS 'Última IP del usuario';

-- Otorgar permisos
GRANT SELECT, INSERT, UPDATE, DELETE ON ps_userdata.users_master TO shaiya_app;

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER users_master_update_updated_at 
    BEFORE UPDATE ON ps_userdata.users_master 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
