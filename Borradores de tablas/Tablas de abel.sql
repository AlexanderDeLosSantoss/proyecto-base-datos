-- TABLA: sede
CREATE TABLE
    sede (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        ciudad VARCHAR(50) NOT NULL,
        direccion VARCHAR(150) NOT NULL,
        telefono VARCHAR(20) NULL,
        CONSTRAINT uq_sede_nombre UNIQUE (nombre)
    );

-- TABLA: departamento
CREATE TABLE
    departamento (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        id_sede INT NOT NULL,
        id_gerente INT NULL, -- FK a empleado, se agrega luego vía ALTER TABLE
        presupuesto_nomina DECIMAL(14, 2) NOT NULL DEFAULT 0,
        CONSTRAINT fk_departamento_sede FOREIGN KEY (id_sede) REFERENCES sede (id) ON DELETE RESTRICT ON UPDATE CASCADE,
        CONSTRAINT uq_departamento_nombre_sede UNIQUE (nombre, id_sede),
        CONSTRAINT chk_departamento_presupuesto CHECK (presupuesto_nomina >= 0),
        INDEX idx_departamento_sede (id_sede)
    );

-- TABLA: puesto
CREATE TABLE
    puesto (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        id_departamento INT NOT NULL,
        salario DECIMAL(10, 2) NOT NULL,
        nivel_jerarquico ENUM (
            'operativo',
            'supervisor',
            'gerencial',
            'directivo'
        ) NOT NULL DEFAULT 'operativo',
        capacitacion_obligatoria BOOLEAN NOT NULL DEFAULT FALSE,
        CONSTRAINT fk_puesto_departamento FOREIGN KEY (id_departamento) REFERENCES departamento (id) ON DELETE RESTRICT ON UPDATE CASCADE,
        CONSTRAINT uq_puesto_nombre_departamento UNIQUE (nombre, id_departamento),
        CONSTRAINT chk_puesto_salario CHECK (salario > 0),
        INDEX idx_puesto_departamento (id_departamento)
    );

-- TABLA: usuario
CREATE TABLE
    usuario (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_empleado INT NOT NULL, -- FK a empleado, se agrega luego vía ALTER TABLE
        nombre_usuario VARCHAR(50) NOT NULL,
        contrasena_hash VARCHAR(255) NOT NULL,
        rol ENUM (
            'Admin RRHH',
            'Gerente',
            'Empleado',
            'Auditor',
            'Contabilidad'
        ) NOT NULL,
        estado ENUM ('activo', 'bloqueado') NOT NULL DEFAULT 'activo',
        ultimo_acceso DATETIME NULL,
        CONSTRAINT uq_usuario_id_empleado UNIQUE (id_empleado), -- relación 1:1 empleado-usuario
        CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
        INDEX idx_usuario_rol (rol)
    );

-- FKS pendientes qie se agregan cuando exista la tabla empleado
ALTER TABLE departamento ADD CONSTRAINT fk_departamento_gerente FOREIGN KEY (id_gerente) REFERENCES empleado (id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE usuario ADD CONSTRAINT fk_usuario_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id) ON DELETE RESTRICT ON UPDATE CASCADE;