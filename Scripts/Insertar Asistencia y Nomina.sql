-- ==============================================================================
-- PROYECTO: Base de Datos de Recursos Humanos (ITN)
-- FASE: Día 8 - Datos de Ejemplo (Paso 3: Transaccionales - Asistencia y Nómina)
-- ==============================================================================

USE rrhh_itn;

-- ------------------------------------------------------------------------------
-- 1. Insertar Registros de Asistencia (Marcajes de una semana típica)
-- ------------------------------------------------------------------------------
INSERT INTO asistencia (id_empleado, fecha, hora_entrada, hora_salida, tipo_marcaje, id_sede, tipo_ausencia) VALUES
(1, '2026-07-27', '2026-07-27 07:55:00', '2026-07-27 17:05:00', 'ENTRADA', 1, NULL),
(2, '2026-07-27', '2026-07-27 08:00:00', '2026-07-27 17:00:00', 'ENTRADA', 3, NULL),
(3, '2026-07-27', '2026-07-27 08:10:00', '2026-07-27 17:30:00', 'ENTRADA', 3, NULL),
(4, '2026-07-27', '2026-07-27 08:00:00', NULL, 'ENTRADA', 1, 'JUSTIFICADA'), -- Permiso médico en la tarde
(5, '2026-07-27', '2026-07-27 07:45:00', '2026-07-27 18:00:00', 'ENTRADA', 1, NULL), -- Hizo horas extras

(1, '2026-07-28', '2026-07-28 07:58:00', '2026-07-28 17:00:00', 'ENTRADA', 1, NULL),
(2, '2026-07-28', '2026-07-28 07:55:00', '2026-07-28 17:15:00', 'ENTRADA', 3, NULL),
(5, '2026-07-28', '2026-07-28 08:00:00', '2026-07-28 17:00:00', 'ENTRADA', 1, NULL);

-- ------------------------------------------------------------------------------
-- 2. Insertar Lote de Nómina (Cierre de Mes - Julio 2026)
-- ------------------------------------------------------------------------------
INSERT INTO nomina (id_empleado, periodo, fecha_pago, salario_bruto, deduccion_tss, deduccion_afp, deduccion_isr, bonificaciones, horas_extras, salario_neto, estado_pago) VALUES
(1, 'MENSUAL', '2026-07-30', 85000.00, 2584.00, 2439.50, 6000.00, 0.00, 0.00, 73976.50, 'PAGADO'),
(2, 'MENSUAL', '2026-07-30', 120000.00, 3648.00, 3444.00, 14000.00, 5000.00, 0.00, 103908.00, 'PAGADO'),
(3, 'MENSUAL', '2026-07-30', 40000.00, 1216.00, 1148.00, 0.00, 0.00, 1500.00, 39136.00, 'PENDIENTE'),
(4, 'MENSUAL', '2026-07-30', 45000.00, 1368.00, 1291.50, 400.00, 0.00, 0.00, 41940.50, 'PENDIENTE'),
(5, 'MENSUAL', '2026-07-30', 25000.00, 760.00, 717.50, 0.00, 0.00, 2500.00, 26022.50, 'PAGADO');

-- Validar inserciones
SELECT 'Datos transaccionales insertados correctamente' AS Estado;