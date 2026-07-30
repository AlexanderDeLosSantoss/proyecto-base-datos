-- ==============================================================================
-- PROYECTO: Base de Datos de Recursos Humanos (ITN)
-- FASE: Día 9 - Funciones, Procedimientos Almacenados y Triggers
-- ==============================================================================

USE rrhh_itn;

-- ------------------------------------------------------------------------------
-- 1. FUNCIONES (Functions)
-- Objetivo: Cálculos reutilizables en consultas y reportes.
-- ------------------------------------------------------------------------------

-- Función para calcular los años de antigüedad de un empleado
DELIMITER //
CREATE FUNCTION fn_calcular_antiguedad(p_fecha_ingreso DATE) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_anios INT;
    SET v_anios = TIMESTAMPDIFF(YEAR, p_fecha_ingreso, CURDATE());
    RETURN v_anios;
END //
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 2. PROCEDIMIENTOS ALMACENADOS (Stored Procedures)
-- Objetivo: Encapsular lógica de negocio transaccional compleja.
-- ------------------------------------------------------------------------------

-- SP para registrar un nuevo contrato y actualizar automáticamente al empleado
-- Esto resuelve la "triplicación de salarios" manteniendo todo sincronizado.
DELIMITER //
CREATE PROCEDURE sp_registrar_nuevo_contrato(
    IN p_id_empleado INT,
    IN p_id_puesto INT,
    IN p_tipo_contrato ENUM('INDEFINIDO','TEMPORAL','POR_OBRA','PASANTIA'),
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_salario_pactado DECIMAL(10,2)
)
BEGIN
    -- Manejo de errores: Si algo falla, se deshacen los cambios (Rollback)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Inactivar contratos anteriores del empleado
    UPDATE contrato 
    SET estado = 'INACTIVO', motivo_finalizacion = 'Renovación / Cambio de puesto'
    WHERE id_empleado = p_id_empleado AND estado = 'ACTIVO';

    -- 2. Insertar el nuevo contrato legal
    INSERT INTO contrato (id_empleado, id_puesto, tipo_contrato, fecha_inicio, fecha_fin, salario_pactado, estado)
    VALUES (p_id_empleado, p_id_puesto, p_tipo_contrato, p_fecha_inicio, p_fecha_fin, p_salario_pactado, 'ACTIVO');

    -- 3. Sincronizar el puesto y el salario vigente en el perfil del empleado
    UPDATE empleado
    SET id_puesto = p_id_puesto,
        salario_actual = p_salario_pactado
    WHERE id = p_id_empleado;

    COMMIT;
END //
DELIMITER ;

-- ------------------------------------------------------------------------------
-- 3. DISPARADORES (Triggers)
-- Objetivo: Auditoría estricta e invisible para los usuarios finales.
-- ------------------------------------------------------------------------------

-- Trigger para auditar cualquier cambio en el salario actual de un empleado
DELIMITER //
CREATE TRIGGER trg_auditoria_salario
AFTER UPDATE ON empleado
FOR EACH ROW
BEGIN
    -- Solo insertamos en auditoría si el salario realmente cambió
    IF OLD.salario_actual <> NEW.salario_actual THEN
        INSERT INTO auditoria (
            id_usuario, 
            tabla_afectada, 
            id_registro_afectado, 
            tipo_operacion, 
            valor_anterior, 
            valor_nuevo
        )
        VALUES (
            1, -- Asumimos el usuario 1 (Admin/Sistema) por defecto. En una app real, esto viene de variables de sesión.
            'empleado',
            NEW.id,
            'UPDATE',
            JSON_OBJECT('salario_anterior', OLD.salario_actual),
            JSON_OBJECT('salario_nuevo', NEW.salario_actual)
        );
    END IF;
END //
DELIMITER ;

-- Validar creación exitosa
SELECT 'Funciones, SPs y Triggers creados exitosamente' AS Estado;