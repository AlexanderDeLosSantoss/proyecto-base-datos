USE rrhh_itn;

DROP VIEW IF EXISTS vista_empleado_detalle;
DROP VIEW IF EXISTS vista_contratos_activos;
DROP VIEW IF EXISTS vista_nomina_departamento;
DROP VIEW IF EXISTS vista_directorio_empleados;
DROP VIEW IF EXISTS vista_reporte_nomina_contabilidad;
DROP FUNCTION IF EXISTS fn_calcular_antiguedad;
DROP FUNCTION IF EXISTS fn_salario_vigente;
DROP PROCEDURE IF EXISTS sp_registrar_nuevo_contrato;
DROP PROCEDURE IF EXISTS sp_procesar_nomina;
DROP PROCEDURE IF EXISTS sp_dar_baja_empleado;
DROP TRIGGER IF EXISTS trg_valida_contrato_activo_unico;
DROP TRIGGER IF EXISTS trg_auditoria_contrato;
DROP TRIGGER IF EXISTS trg_auditoria_empleado;

-- VISTAS

CREATE VIEW vista_empleado_detalle AS
SELECT
    e.id AS id_empleado,
    e.nombres,
    e.apellidos,
    e.cedula,
    e.estado AS estado_empleado,
    p.nombre AS puesto,
    p.nivel_jerarquico,
    d.nombre AS departamento,
    s.nombre AS sede,
    s.ciudad
FROM empleado e
JOIN puesto p ON e.id_puesto = p.id
JOIN departamento d ON p.id_departamento = d.id
JOIN sede s ON d.id_sede = s.id;

CREATE VIEW vista_contratos_activos AS
SELECT
    c.id AS id_contrato,
    c.id_empleado,
    e.nombres,
    e.apellidos,
    c.id_puesto,
    p.nombre AS puesto,
    c.tipo_contrato,
    c.fecha_inicio,
    c.salario_pactado
FROM contrato c
JOIN empleado e ON c.id_empleado = e.id
JOIN puesto p ON c.id_puesto = p.id
WHERE c.estado = 'ACTIVO';

CREATE VIEW vista_nomina_departamento AS
SELECT
    d.id AS id_departamento,
    d.nombre AS departamento,
    n.periodo,
    COUNT(*) AS cantidad_empleados,
    SUM(n.salario_bruto) AS total_bruto,
    SUM(n.deduccion_tss + n.deduccion_afp + n.deduccion_isr) AS total_deducciones,
    SUM(n.bonificaciones + n.horas_extras) AS total_bonificaciones_extras,
    SUM(n.salario_neto) AS total_neto
FROM nomina n
JOIN empleado e ON n.id_empleado = e.id
JOIN puesto p ON e.id_puesto = p.id
JOIN departamento d ON p.id_departamento = d.id
WHERE n.estado_pago <> 'ANULADO'
GROUP BY d.id, d.nombre, n.periodo;

-- Directorio público: sin cédula ni datos bancarios/salariales, para usuarios de nivel bajo
CREATE VIEW vista_directorio_empleados AS
SELECT
    e.id AS id_empleado,
    CONCAT(e.nombres, ' ', e.apellidos) AS nombre_completo,
    e.email,
    e.telefono,
    p.nombre AS puesto,
    d.nombre AS departamento,
    s.ciudad AS ubicacion_sede
FROM empleado e
JOIN puesto p ON e.id_puesto = p.id
JOIN departamento d ON p.id_departamento = d.id
JOIN sede s ON d.id_sede = s.id
WHERE e.estado = 'ACTIVO';

-- Reporte de nómina por pago individual, para el departamento de Contabilidad
CREATE VIEW vista_reporte_nomina_contabilidad AS
SELECT
    n.id AS folio_nomina,
    n.periodo,
    n.fecha_pago,
    CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
    d.nombre AS departamento,
    n.salario_bruto,
    (n.deduccion_tss + n.deduccion_afp + n.deduccion_isr) AS total_deducciones,
    (n.bonificaciones + n.horas_extras) AS total_ingresos_extra,
    n.salario_neto,
    n.estado_pago
FROM nomina n
JOIN empleado e ON n.id_empleado = e.id
JOIN puesto p ON e.id_puesto = p.id
JOIN departamento d ON p.id_departamento = d.id;

-- FUNCIONES

DELIMITER //
CREATE FUNCTION fn_calcular_antiguedad(p_fecha_ingreso DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_fecha_ingreso, CURDATE());
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION fn_salario_vigente(p_id_empleado INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_salario DECIMAL(10,2);
    SELECT salario_pactado INTO v_salario
    FROM contrato
    WHERE id_empleado = p_id_empleado AND estado = 'ACTIVO'
    LIMIT 1;
    RETURN v_salario;
END //
DELIMITER ;

-- PROCEDIMIENTOS ALMACENADOS

-- Registra un nuevo contrato (renovación, promoción o cambio de puesto),
-- inactivando el anterior y sincronizando el puesto vigente del empleado.
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE contrato
    SET estado = 'INACTIVO', fecha_fin = p_fecha_inicio, motivo_finalizacion = 'Renovación / Cambio de puesto'
    WHERE id_empleado = p_id_empleado AND estado = 'ACTIVO';

    INSERT INTO contrato (id_empleado, id_puesto, tipo_contrato, fecha_inicio, fecha_fin, salario_pactado, estado)
    VALUES (p_id_empleado, p_id_puesto, p_tipo_contrato, p_fecha_inicio, p_fecha_fin, p_salario_pactado, 'ACTIVO');

    UPDATE empleado
    SET id_puesto = p_id_puesto
    WHERE id = p_id_empleado;

    COMMIT;
END //
DELIMITER ;

-- Procesa la nómina de un empleado para un periodo, calculando TSS, AFP e ISR
DELIMITER //
CREATE PROCEDURE sp_procesar_nomina(
    IN p_id_empleado INT,
    IN p_periodo VARCHAR(15),
    IN p_fecha_pago DATE,
    IN p_bonificaciones DECIMAL(10,2),
    IN p_horas_extras DECIMAL(10,2)
)
BEGIN
    DECLARE v_bruto DECIMAL(10,2);
    DECLARE v_tss DECIMAL(10,2);
    DECLARE v_afp DECIMAL(10,2);
    DECLARE v_isr DECIMAL(10,2);
    DECLARE v_neto DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT salario_pactado INTO v_bruto
    FROM contrato
    WHERE id_empleado = p_id_empleado AND estado = 'ACTIVO'
    LIMIT 1;

    IF v_bruto IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede procesar la nómina: el empleado no tiene contrato activo.';
    END IF;

    SET v_tss = ROUND(v_bruto * 0.0304, 2);
    SET v_afp = ROUND(v_bruto * 0.0287, 2);

    IF v_bruto <= 34685 THEN
        SET v_isr = 0;
    ELSEIF v_bruto <= 52380 THEN
        SET v_isr = ROUND((v_bruto - 34685) * 0.15, 2);
    ELSEIF v_bruto <= 72785 THEN
        SET v_isr = ROUND(2654.25 + (v_bruto - 52380) * 0.20, 2);
    ELSE
        SET v_isr = ROUND(6735.25 + (v_bruto - 72785) * 0.25, 2);
    END IF;

    SET v_neto = v_bruto - v_tss - v_afp - v_isr + IFNULL(p_bonificaciones, 0) + IFNULL(p_horas_extras, 0);

    START TRANSACTION;

    INSERT INTO nomina (id_empleado, periodo, fecha_pago, salario_bruto, deduccion_tss, deduccion_afp,
                         deduccion_isr, bonificaciones, horas_extras, salario_neto, estado_pago)
    VALUES (p_id_empleado, p_periodo, p_fecha_pago, v_bruto, v_tss, v_afp,
            v_isr, IFNULL(p_bonificaciones, 0), IFNULL(p_horas_extras, 0), v_neto, 'PENDIENTE');

    COMMIT;
END //
DELIMITER ;

-- Da de baja lógica a un empleado: inactiva su contrato vigente y su estado.
-- No se permite el borrado físico.
DELIMITER //
CREATE PROCEDURE sp_dar_baja_empleado(
    IN p_id_empleado INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE contrato
    SET estado = 'INACTIVO', fecha_fin = CURDATE(), motivo_finalizacion = p_motivo
    WHERE id_empleado = p_id_empleado AND estado = 'ACTIVO';

    UPDATE empleado
    SET estado = 'INACTIVO'
    WHERE id = p_id_empleado;

    COMMIT;
END //
DELIMITER ;

-- TRIGGERS

-- Impide que un empleado tenga dos contratos activos simultáneamente.
DELIMITER //
CREATE TRIGGER trg_valida_contrato_activo_unico
BEFORE INSERT ON contrato
FOR EACH ROW
BEGIN
    DECLARE v_existe INT;
    IF NEW.estado = 'ACTIVO' THEN
        SELECT COUNT(*) INTO v_existe
        FROM contrato
        WHERE id_empleado = NEW.id_empleado AND estado = 'ACTIVO';

        IF v_existe > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El empleado ya tiene un contrato activo. Debe inactivarlo antes de crear uno nuevo.';
        END IF;
    END IF;
END //
DELIMITER ;

-- Audita cambios de estado o salario pactado en los contratos
DELIMITER //
CREATE TRIGGER trg_auditoria_contrato
AFTER UPDATE ON contrato
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado OR OLD.salario_pactado <> NEW.salario_pactado THEN
        INSERT INTO auditoria (id_usuario, tabla_afectada, id_registro_afectado, tipo_operacion, valor_anterior, valor_nuevo)
        VALUES (
            1,
            'contrato',
            NEW.id,
            'UPDATE',
            JSON_OBJECT('estado', OLD.estado, 'salario_pactado', OLD.salario_pactado),
            JSON_OBJECT('estado', NEW.estado, 'salario_pactado', NEW.salario_pactado)
        );
    END IF;
END //
DELIMITER ;

-- Audita cambios sensibles en el empleado (estado o puesto vigente)
DELIMITER //
CREATE TRIGGER trg_auditoria_empleado
AFTER UPDATE ON empleado
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado OR OLD.id_puesto <> NEW.id_puesto THEN
        INSERT INTO auditoria (id_usuario, tabla_afectada, id_registro_afectado, tipo_operacion, valor_anterior, valor_nuevo)
        VALUES (
            1,
            'empleado',
            NEW.id,
            'UPDATE',
            JSON_OBJECT('estado', OLD.estado, 'id_puesto', OLD.id_puesto),
            JSON_OBJECT('estado', NEW.estado, 'id_puesto', NEW.id_puesto)
        );
    END IF;
END //
DELIMITER ;

SELECT 'Vistas, funciones, procedimientos y triggers creados exitosamente' AS Estado;