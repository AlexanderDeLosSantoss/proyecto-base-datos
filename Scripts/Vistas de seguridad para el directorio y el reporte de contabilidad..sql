-- ==============================================================================
-- PROYECTO: Base de Datos de Recursos Humanos (ITN)
-- FASE: Día 8 - Creación de Vistas (Seguridad y Reportes)
-- ==============================================================================

USE rrhh_itn;

-- ------------------------------------------------------------------------------
-- VISTA 1: Directorio Público de Empleados
-- Objetivo: Mostrar información de contacto básica, ocultando datos sensibles 
-- (salario, cédula, datos bancarios) para usuarios de nivel bajo.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_directorio_empleados AS
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

-- ------------------------------------------------------------------------------
-- VISTA 2: Reporte de Nómina Consolidada para Contabilidad
-- Objetivo: Entregar un reporte financiero limpio con los nombres y departamentos,
-- listo para ser exportado o consumido por el sistema contable externo.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_reporte_nomina_contabilidad AS
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

-- Validar creación exitosa
SELECT 'Vistas de seguridad y reportes creadas exitosamente' AS Estado;