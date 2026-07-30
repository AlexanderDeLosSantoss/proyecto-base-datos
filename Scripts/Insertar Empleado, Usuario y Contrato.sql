-- ==============================================================================
-- PROYECTO: Base de Datos de Recursos Humanos (ITN)
-- FASE: Día 8 - Datos de Ejemplo (Paso 2: Entidades Core)
-- ==============================================================================

USE rrhh_itn;

-- ------------------------------------------------------------------------------
-- 1. Insertar Empleados
-- ------------------------------------------------------------------------------
INSERT INTO empleado (nombres, apellidos, cedula, fecha_nacimiento, telefono, genero, direccion, email, fecha_ingreso, estado, id_puesto, salario_actual, banco, numero_cuenta) VALUES
('Juan', 'Pérez', '001-1234567-1', '1985-05-15', '809-555-0111', 'M', 'Calle A #1, Ensanche Piantini', 'juan.perez@itn.com', '2020-01-10', 'ACTIVO', 3, 85000.00, 'Banco Popular', '123456789'),
('María', 'Gómez', '001-7654321-2', '1990-08-20', '809-555-0222', 'F', 'Calle B #2, Naco', 'maria.gomez@itn.com', '2021-03-15', 'ACTIVO', 6, 120000.00, 'Banreservas', '987654321'),
('Carlos', 'López', '001-1122334-3', '1992-11-05', '809-555-0333', 'M', 'Calle C #3, Los Prados', 'carlos.lopez@itn.com', '2022-06-01', 'ACTIVO', 5, 40000.00, 'BHD León', '555666777'),
('Ana', 'Martínez', '001-4455667-4', '1988-02-14', '809-555-0444', 'F', 'Calle D #4, Bella Vista', 'ana.martinez@itn.com', '2019-09-20', 'ACTIVO', 2, 45000.00, 'Banco Popular', '111222333'),
('Luis', 'Rodríguez', '001-9988776-5', '1995-07-30', '809-555-0555', 'M', 'Calle E #5, Herrera', 'luis.rodriguez@itn.com', '2023-01-15', 'ACTIVO', 1, 25000.00, 'Banreservas', '444555666');

-- ------------------------------------------------------------------------------
-- 2. Asignar Gerentes a los Departamentos (Resolución de dependencia)
-- El empleado 1 (Juan) es Gerente de Producción (depto 1)
-- La empleada 2 (María) es Directora de Finanzas (depto 4)
-- ------------------------------------------------------------------------------
UPDATE departamento SET id_gerente = 1 WHERE id = 1; 
UPDATE departamento SET id_gerente = 2 WHERE id = 4; 

-- ------------------------------------------------------------------------------
-- 3. Insertar Usuarios del Sistema
-- Usamos las restricciones ENUM correctas ('Admin RRHH', 'Gerente', etc.)
-- ------------------------------------------------------------------------------
INSERT INTO usuario (id_empleado, nombre_usuario, contrasena_hash, rol, estado, ultimo_acceso) VALUES
(1, 'jperez', 'hash_seguro_123', 'Gerente', 'activo', '2026-07-30 08:00:00'),
(2, 'mgomez', 'hash_seguro_456', 'Contabilidad', 'activo', '2026-07-30 08:15:00'),
(3, 'clopez', 'hash_seguro_789', 'Admin RRHH', 'activo', '2026-07-30 07:45:00'),
(4, 'amartinez', 'hash_seguro_321', 'Empleado', 'activo', '2026-07-30 07:50:00'),
(5, 'lrodriguez', 'hash_seguro_654', 'Empleado', 'activo', '2026-07-30 06:55:00');

-- ------------------------------------------------------------------------------
-- 4. Insertar Historial de Contratos
-- Nótese que algunos salarios_pactados iniciales son menores que el salario_actual
-- para simular que han recibido aumentos en el tiempo.
-- ------------------------------------------------------------------------------
INSERT INTO contrato (id_empleado, id_puesto, tipo_contrato, fecha_inicio, fecha_fin, salario_pactado, estado, motivo_finalizacion) VALUES
(1, 3, 'INDEFINIDO', '2020-01-10', NULL, 80000.00, 'ACTIVO', NULL), 
(2, 6, 'INDEFINIDO', '2021-03-15', NULL, 110000.00, 'ACTIVO', NULL),
(3, 5, 'INDEFINIDO', '2022-06-01', NULL, 35000.00, 'ACTIVO', NULL),
(4, 2, 'INDEFINIDO', '2019-09-20', NULL, 42000.00, 'ACTIVO', NULL),
(5, 1, 'TEMPORAL', '2023-01-15', '2024-01-15', 25000.00, 'ACTIVO', NULL);

-- Validar inserciones
SELECT 'Entidades Core insertadas correctamente' AS Estado;