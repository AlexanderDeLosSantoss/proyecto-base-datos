-- ==============================================================================
-- PROYECTO: Base de Datos de Recursos Humanos (ITN)
-- FASE: Día 8 - Datos de Ejemplo (Paso 1: Catálogos Base)
-- ==============================================================================

USE rrhh_itn;

-- ------------------------------------------------------------------------------
-- 1. Insertar Sedes de la Empresa
-- ------------------------------------------------------------------------------
INSERT INTO sede (nombre, ciudad, direccion, telefono) VALUES
('Planta Central Textil', 'Santo Domingo', 'Av. Industrial #45, Zona Franca', '809-555-0100'),
('Centro de Distribución Norte', 'Santiago', 'Autopista Duarte Km 5', '809-555-0200'),
('Oficinas Administrativas', 'Santo Domingo', 'Av. Winston Churchill #1050', '809-555-0300');

-- ------------------------------------------------------------------------------
-- 2. Insertar Departamentos 
-- Nota: id_gerente queda en NULL temporalmente hasta que insertemos empleados
-- ------------------------------------------------------------------------------
INSERT INTO departamento (nombre, id_sede, id_gerente, presupuesto_nomina) VALUES
('Producción y Manufactura', 1, NULL, 500000.00),
('Logística y Despacho', 2, NULL, 250000.00),
('Recursos Humanos', 3, NULL, 150000.00),
('Contabilidad y Finanzas', 3, NULL, 180000.00);

-- ------------------------------------------------------------------------------
-- 3. Insertar Puestos de Trabajo
-- ------------------------------------------------------------------------------
INSERT INTO puesto (nombre, id_departamento, salario, nivel_jerarquico, capacitacion_obligatoria) VALUES
('Operario de Costura', 1, 25000.00, 'operativo', TRUE),
('Supervisor de Planta', 1, 45000.00, 'supervisor', TRUE),
('Gerente de Producción', 1, 85000.00, 'gerencial', FALSE),
('Montacarguista', 2, 28000.00, 'operativo', TRUE),
('Analista de Nómina', 3, 40000.00, 'operativo', FALSE),
('Director de Finanzas', 4, 120000.00, 'directivo', FALSE);

-- Validar inserciones
SELECT 'Catálogos insertados correctamente' AS Estado;

