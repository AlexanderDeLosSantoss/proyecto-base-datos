USE rrhh_itn;

-- Nómina por departamento comparada con el periodo anterior
SELECT
    d.nombre AS departamento,
    n.periodo,
    SUM(n.salario_neto) AS total_neto_actual,
    LAG(SUM(n.salario_neto)) OVER (PARTITION BY d.id ORDER BY n.periodo) AS total_neto_periodo_anterior,
    ROUND((SUM(n.salario_neto) - LAG(SUM(n.salario_neto)) OVER (PARTITION BY d.id ORDER BY n.periodo))
        / LAG(SUM(n.salario_neto)) OVER (PARTITION BY d.id ORDER BY n.periodo) * 100, 2) AS variacion_porcentual
FROM nomina n
JOIN empleado e ON n.id_empleado = e.id
JOIN puesto p ON e.id_puesto = p.id
JOIN departamento d ON p.id_departamento = d.id
WHERE n.estado_pago <> 'ANULADO'
GROUP BY d.id, d.nombre, n.periodo
ORDER BY d.nombre, n.periodo;

-- Costo de nómina proyectado (presupuesto) vs real por departamento
SELECT
    d.nombre AS departamento,
    n.periodo,
    d.presupuesto_nomina AS presupuesto_asignado,
    SUM(n.salario_bruto) AS costo_real_bruto,
    ROUND(d.presupuesto_nomina - SUM(n.salario_bruto), 2) AS diferencia,
    ROUND(SUM(n.salario_bruto) / d.presupuesto_nomina * 100, 2) AS porcentaje_ejecutado,
    CASE
        WHEN SUM(n.salario_bruto) > d.presupuesto_nomina THEN 'EXCEDE PRESUPUESTO'
        WHEN SUM(n.salario_bruto) > d.presupuesto_nomina * 0.9 THEN 'CERCA DEL LIMITE'
        ELSE 'DENTRO DE PRESUPUESTO'
    END AS estado_presupuestal
FROM departamento d
JOIN puesto p ON p.id_departamento = d.id
JOIN empleado e ON e.id_puesto = p.id
JOIN nomina n ON n.id_empleado = e.id
WHERE n.estado_pago <> 'ANULADO'
GROUP BY d.id, d.nombre, n.periodo, d.presupuesto_nomina
ORDER BY porcentaje_ejecutado DESC;

-- Departamentos que en algún periodo superaron su presupuesto de nómina
SELECT d.id, d.nombre AS departamento, d.presupuesto_nomina
FROM departamento d
WHERE EXISTS (
    SELECT 1
    FROM nomina n
    JOIN empleado e ON n.id_empleado = e.id
    JOIN puesto p ON e.id_puesto = p.id
    WHERE p.id_departamento = d.id AND n.estado_pago <> 'ANULADO'
    GROUP BY n.periodo
    HAVING SUM(n.salario_bruto) > d.presupuesto_nomina
);

-- Ausentismo por empleado y departamento en un periodo
SET @periodo_inicio = '2026-07-01';
SET @periodo_fin = '2026-07-31';

WITH RECURSIVE calendario AS (
    SELECT @periodo_inicio AS fecha
    UNION ALL
    SELECT DATE_ADD(fecha, INTERVAL 1 DAY) FROM calendario WHERE fecha < @periodo_fin
),
dias_habiles AS (
    SELECT fecha FROM calendario WHERE DAYOFWEEK(fecha) NOT IN (1, 7)
),
empleados_activos AS (
    SELECT e.id AS id_empleado, e.nombres, e.apellidos, d.id AS id_departamento, d.nombre AS departamento
    FROM empleado e
    JOIN puesto p ON e.id_puesto = p.id
    JOIN departamento d ON p.id_departamento = d.id
    WHERE e.estado = 'ACTIVO'
),
matriz_esperada AS (
    SELECT ea.id_empleado, ea.nombres, ea.apellidos, ea.id_departamento, ea.departamento, dh.fecha
    FROM empleados_activos ea
    CROSS JOIN dias_habiles dh
)
SELECT
    me.id_departamento,
    me.departamento,
    me.id_empleado,
    CONCAT(me.nombres, ' ', me.apellidos) AS empleado,
    COUNT(*) AS dias_esperados,
    SUM(CASE WHEN a.id IS NULL OR a.tipo_ausencia IS NOT NULL THEN 1 ELSE 0 END) AS dias_ausente,
    ROUND(SUM(CASE WHEN a.id IS NULL OR a.tipo_ausencia IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS porcentaje_ausentismo
FROM matriz_esperada me
LEFT JOIN asistencia a ON a.id_empleado = me.id_empleado AND a.fecha = me.fecha
GROUP BY me.id_departamento, me.departamento, me.id_empleado, me.nombres, me.apellidos
ORDER BY porcentaje_ausentismo DESC;

-- Rotación de personal (altas y bajas) por departamento y mes
WITH altas AS (
    SELECT p.id_departamento, DATE_FORMAT(c.fecha_inicio, '%Y-%m') AS periodo, COUNT(*) AS total_altas
    FROM contrato c
    JOIN puesto p ON c.id_puesto = p.id
    GROUP BY p.id_departamento, DATE_FORMAT(c.fecha_inicio, '%Y-%m')
),
bajas AS (
    SELECT p.id_departamento, DATE_FORMAT(c.fecha_fin, '%Y-%m') AS periodo, COUNT(*) AS total_bajas
    FROM contrato c
    JOIN puesto p ON c.id_puesto = p.id
    WHERE c.fecha_fin IS NOT NULL
    GROUP BY p.id_departamento, DATE_FORMAT(c.fecha_fin, '%Y-%m')
),
plantilla AS (
    SELECT p.id_departamento, COUNT(*) AS empleados_activos
    FROM empleado e
    JOIN puesto p ON e.id_puesto = p.id
    WHERE e.estado = 'ACTIVO'
    GROUP BY p.id_departamento
)
SELECT
    d.nombre AS departamento,
    COALESCE(al.periodo, ba.periodo) AS periodo,
    COALESCE(al.total_altas, 0) AS altas,
    COALESCE(ba.total_bajas, 0) AS bajas,
    pl.empleados_activos,
    ROUND(COALESCE(ba.total_bajas, 0) / NULLIF(pl.empleados_activos, 0) * 100, 2) AS tasa_rotacion_pct
FROM departamento d
JOIN plantilla pl ON pl.id_departamento = d.id
LEFT JOIN altas al ON al.id_departamento = d.id
LEFT JOIN bajas ba ON ba.id_departamento = d.id AND ba.periodo = al.periodo
WHERE al.periodo IS NOT NULL OR ba.periodo IS NOT NULL
ORDER BY departamento, periodo;

-- Ranking salarial dentro de cada puesto
SELECT
    p.nombre AS puesto,
    CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
    c.salario_pactado,
    RANK() OVER (PARTITION BY p.id ORDER BY c.salario_pactado DESC) AS posicion_rank,
    DENSE_RANK() OVER (PARTITION BY p.id ORDER BY c.salario_pactado DESC) AS posicion_dense_rank,
    ROUND(PERCENT_RANK() OVER (PARTITION BY p.id ORDER BY c.salario_pactado), 2) AS percentil
FROM contrato c
JOIN empleado e ON c.id_empleado = e.id
JOIN puesto p ON c.id_puesto = p.id
WHERE c.estado = 'ACTIVO'
ORDER BY puesto, posicion_rank;

-- Top 3 empleados mejor pagados por departamento
WITH salarios_departamento AS (
    SELECT
        d.nombre AS departamento,
        CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
        p.nombre AS puesto,
        c.salario_pactado,
        ROW_NUMBER() OVER (PARTITION BY d.id ORDER BY c.salario_pactado DESC) AS posicion
    FROM contrato c
    JOIN empleado e ON c.id_empleado = e.id
    JOIN puesto p ON c.id_puesto = p.id
    JOIN departamento d ON p.id_departamento = d.id
    WHERE c.estado = 'ACTIVO'
)
SELECT * FROM salarios_departamento WHERE posicion <= 3 ORDER BY departamento, posicion;

-- Antigüedad de empleados agrupada por rangos
SELECT
    CASE
        WHEN fn_calcular_antiguedad(e.fecha_ingreso) < 1 THEN '01. Menos de 1 año'
        WHEN fn_calcular_antiguedad(e.fecha_ingreso) < 3 THEN '02. 1 a 3 años'
        WHEN fn_calcular_antiguedad(e.fecha_ingreso) < 5 THEN '03. 3 a 5 años'
        WHEN fn_calcular_antiguedad(e.fecha_ingreso) < 10 THEN '04. 5 a 10 años'
        ELSE '05. Más de 10 años'
    END AS rango_antiguedad,
    COUNT(*) AS cantidad_empleados,
    ROUND(AVG(fn_salario_vigente(e.id)), 2) AS salario_promedio
FROM empleado e
WHERE e.estado = 'ACTIVO'
GROUP BY rango_antiguedad
ORDER BY rango_antiguedad;

-- Contratos próximos a vencer en los siguientes 30 días
SELECT
    CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
    p.nombre AS puesto,
    d.nombre AS departamento,
    c.tipo_contrato,
    c.fecha_fin,
    DATEDIFF(c.fecha_fin, CURDATE()) AS dias_restantes
FROM contrato c
JOIN empleado e ON c.id_empleado = e.id
JOIN puesto p ON c.id_puesto = p.id
JOIN departamento d ON p.id_departamento = d.id
WHERE c.estado = 'ACTIVO'
  AND c.fecha_fin IS NOT NULL
  AND c.fecha_fin BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY c.fecha_fin ASC;

-- Empleados con marcaje de entrada sin salida registrada
SELECT
    CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
    s.nombre AS sede,
    a.fecha,
    a.hora_entrada,
    a.tipo_marcaje
FROM asistencia a
JOIN empleado e ON a.id_empleado = e.id
JOIN sede s ON a.id_sede = s.id
WHERE a.hora_salida IS NULL AND a.fecha < CURDATE()
ORDER BY a.fecha DESC;

-- Empleados que ganan más que el gerente de su propio departamento
SELECT
    d.nombre AS departamento,
    CONCAT(g.nombres, ' ', g.apellidos) AS gerente,
    fn_salario_vigente(g.id) AS salario_gerente,
    CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
    fn_salario_vigente(e.id) AS salario_empleado,
    fn_salario_vigente(e.id) - fn_salario_vigente(g.id) AS diferencia
FROM departamento d
JOIN empleado g ON d.id_gerente = g.id
JOIN puesto p ON p.id_departamento = d.id
JOIN empleado e ON e.id_puesto = p.id AND e.id <> g.id
WHERE fn_salario_vigente(e.id) > fn_salario_vigente(g.id)
ORDER BY diferencia DESC;

-- Auditoría de cambios: resumen por usuario y tabla
SELECT
    u.nombre_usuario,
    u.rol,
    a.tabla_afectada,
    SUM(CASE WHEN a.tipo_operacion = 'INSERT' THEN 1 ELSE 0 END) AS total_inserts,
    SUM(CASE WHEN a.tipo_operacion = 'UPDATE' THEN 1 ELSE 0 END) AS total_updates,
    SUM(CASE WHEN a.tipo_operacion = 'DELETE' THEN 1 ELSE 0 END) AS total_deletes,
    COUNT(*) AS total_cambios,
    MAX(a.fecha) AS ultimo_cambio,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking_actividad
FROM auditoria a
JOIN usuario u ON a.id_usuario = u.id
GROUP BY u.id, u.nombre_usuario, u.rol, a.tabla_afectada
ORDER BY ranking_actividad;

-- Total de nómina por sede y departamento con subtotales y gran total
SELECT
    COALESCE(s.nombre, 'TOTAL GENERAL') AS sede,
    COALESCE(d.nombre, 'Subtotal sede') AS departamento,
    ROUND(SUM(n.salario_neto), 2) AS total_nomina_neta
FROM nomina n
JOIN empleado e ON n.id_empleado = e.id
JOIN puesto p ON e.id_puesto = p.id
JOIN departamento d ON p.id_departamento = d.id
JOIN sede s ON d.id_sede = s.id
WHERE n.estado_pago <> 'ANULADO'
GROUP BY s.nombre, d.nombre WITH ROLLUP
ORDER BY s.nombre, d.nombre;

-- Nómina neta acumulada por empleado (running total)
SELECT
    CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
    n.periodo,
    n.fecha_pago,
    n.salario_neto,
    SUM(n.salario_neto) OVER (PARTITION BY e.id ORDER BY n.fecha_pago ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS acumulado_pagado
FROM nomina n
JOIN empleado e ON n.id_empleado = e.id
WHERE n.estado_pago = 'PAGADO'
ORDER BY empleado, n.fecha_pago;
