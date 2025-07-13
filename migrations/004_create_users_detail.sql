-- Migration 004: Crear tabla users_detail
-- Fecha: 2025-07-13
-- Descripción: Tabla de detalles adicionales de usuarios

CREATE TABLE ps_userdata.users_detail (
    userno INTEGER NOT NULL,
    detail_col1 VARCHAR(255),
    detail_col2 VARCHAR(255),
    detail_col3 VARCHAR(255),
    detail_col4 VARCHAR(255),
    
    -- Campos adicionales de perfil
    email VARCHAR(255),
    phone VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    birth_date DATE,
    gender CHAR(1),
    
    -- Timestamps de auditoría
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint principal
    CONSTRAINT users_detail_pkey PRIMARY KEY (userno),
    
    -- Foreign key a users_master
    CONSTRAINT users_detail_userno_fkey FOREIGN KEY (userno) REFERENCES ps_userdata.users_master(userno) ON DELETE CASCADE,
    
    -- Constraints de validación
    CONSTRAINT users_detail_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT users_detail_gender_check CHECK (gender IN ('M', 'F', 'O'))
);

-- Índices
CREATE INDEX idx_users_detail_userno ON ps_userdata.users_detail(userno);
CREATE INDEX idx_users_detail_email ON ps_userdata.users_detail(email);
CREATE INDEX idx_users_detail_country ON ps_userdata.users_detail(country);

-- Comentarios
COMMENT ON TABLE ps_userdata.users_detail IS 'Tabla de detalles adicionales de usuarios';
COMMENT ON COLUMN ps_userdata.users_detail.userno IS 'Referencia al número de usuario en users_master';
COMMENT ON COLUMN ps_userdata.users_detail.email IS 'Email del usuario';
COMMENT ON COLUMN ps_userdata.users_detail.gender IS 'Género: M=Masculino, F=Femenino, O=Otro';

-- Permisos
GRANT SELECT, INSERT, UPDATE, DELETE ON ps_userdata.users_detail TO shaiya_app;

-- Trigger para updated_at
CREATE TRIGGER users_detail_update_updated_at 
    BEFORE UPDATE ON ps_userdata.users_detail 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
