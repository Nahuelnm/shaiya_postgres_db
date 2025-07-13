-- Migration 005: Insertar datos iniciales de usuarios
-- Fecha: 2025-07-13
-- Descripción: Datos iniciales migrados desde SQL Server

-- Insertar usuarios migrados
INSERT INTO ps_userdata.users_master (
    userid, userno, username, userpw, date1, privilege, status, points, warning, banreason, 
    date2, delcharacter, nation, grow, gamepoint, user_ip, ggauth, col18
) VALUES 
(1, 1, 'gmnitrous', 'Sharingan14', '2021-01-30 15:19:00', 1, 255, 0, 16, 0, 
 '2031-01-30 15:19:00', 'A', NULL, NULL, NULL, 0, NULL, NULL),

(2, 2, 'Nitrous.n2o', 'Sharingan14', '2021-02-06 00:00:00', 0, 0, 0, 0, 0, 
 '2031-01-30 00:00:00', 'N', NULL, NULL, NULL, 99999999, NULL, NULL),

(3, 3, 'gmnitrousf', 'Sharingan14', '2021-02-06 00:00:00', 1, 255, 0, 16, 0, 
 '2031-01-30 00:00:00', 'A', NULL, NULL, NULL, 99999999, NULL, NULL)

ON CONFLICT (userid) DO UPDATE SET
    username = EXCLUDED.username,
    userpw = EXCLUDED.userpw,
    date1 = EXCLUDED.date1,
    privilege = EXCLUDED.privilege,
    status = EXCLUDED.status,
    updated_at = CURRENT_TIMESTAMP;

-- Verificar inserción
DO $$
DECLARE
    user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM ps_userdata.users_master;
    RAISE NOTICE 'Total de usuarios después de migración inicial: %', user_count;
    
    IF user_count < 3 THEN
        RAISE EXCEPTION 'Error: No se insertaron todos los usuarios esperados';
    END IF;
END $$;
