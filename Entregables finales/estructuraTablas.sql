CREATE DATABASE IF NOT EXISTS rrhh_itn CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rrhh_itn;

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE sede (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) NULL,
    CONSTRAINT uq_sede_nombre UNIQUE (nombre)
);

CREATE TABLE departamento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_sede INT NOT NULL,
    id_gerente INT NULL,
    presupuesto_nomina DECIMAL(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_departamento_sede FOREIGN KEY (id_sede) REFERENCES sede (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_departamento_gerente FOREIGN KEY (id_gerente) REFERENCES empleado (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT uq_departamento_nombre_sede UNIQUE (nombre, id_sede),
    CONSTRAINT chk_departamento_presupuesto CHECK (presupuesto_nomina >= 0),
    INDEX idx_departamento_sede (id_sede)
);

CREATE TABLE puesto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_departamento INT NOT NULL,
    salario DECIMAL(10,2) NOT NULL,
    nivel_jerarquico ENUM('operativo','supervisor','gerencial','directivo') NOT NULL DEFAULT 'operativo',
    capacitacion_obligatoria BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_puesto_departamento FOREIGN KEY (id_departamento) REFERENCES departamento (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_puesto_nombre_departamento UNIQUE (nombre, id_departamento),
    CONSTRAINT chk_puesto_salario CHECK (salario > 0),
    INDEX idx_puesto_departamento (id_departamento)
);

CREATE TABLE empleado (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cedula VARCHAR(20) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(20) NULL,
    genero ENUM('M','F','OTRO') NULL,
    estado_civil ENUM('SOLTERO','CASADO','DIVORCIADO','VIUDO','UNION_LIBRE') NULL,
    direccion VARCHAR(255) NULL,
    email VARCHAR(150) NULL,
    contacto_emergencia_nombre VARCHAR(150) NULL,
    contacto_emergencia_telefono VARCHAR(20) NULL,
    fecha_ingreso DATE NOT NULL,
    estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    id_puesto INT NOT NULL,
    banco VARCHAR(50) NOT NULL,
    numero_cuenta VARCHAR(50) NOT NULL,
    CONSTRAINT fk_empleado_puesto FOREIGN KEY (id_puesto) REFERENCES puesto (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_empleado_cedula UNIQUE (cedula),
    CONSTRAINT uq_empleado_email UNIQUE (email),
    CONSTRAINT chk_empleado_fechas CHECK (fecha_ingreso >= fecha_nacimiento),
    CONSTRAINT chk_empleado_mayoria_edad CHECK (DATEDIFF(fecha_ingreso, fecha_nacimiento) >= 6570),
    INDEX idx_empleado_puesto (id_puesto),
    INDEX idx_empleado_estado (estado)
);

CREATE TABLE contrato (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    id_puesto INT NOT NULL,
    tipo_contrato ENUM('INDEFINIDO','TEMPORAL','POR_OBRA','PASANTIA') NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    salario_pactado DECIMAL(10,2) NOT NULL,
    estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    motivo_finalizacion VARCHAR(255) NULL,
    CONSTRAINT fk_contrato_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_contrato_puesto FOREIGN KEY (id_puesto) REFERENCES puesto (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_contrato_salario CHECK (salario_pactado >= 0),
    CONSTRAINT chk_contrato_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    INDEX idx_contrato_empleado (id_empleado),
    INDEX idx_contrato_estado (estado),
    INDEX idx_contrato_fechas (fecha_inicio, fecha_fin)
);

CREATE TABLE usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    nombre_usuario VARCHAR(50) NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    rol ENUM('Admin RRHH','Gerente','Empleado','Auditor','Contabilidad') NOT NULL,
    estado ENUM('ACTIVO','BLOQUEADO') NOT NULL DEFAULT 'ACTIVO',
    ultimo_acceso DATETIME NULL,
    CONSTRAINT fk_usuario_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_usuario_id_empleado UNIQUE (id_empleado),
    CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
    INDEX idx_usuario_rol (rol)
);

CREATE TABLE auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    tabla_afectada VARCHAR(50) NOT NULL,
    id_registro_afectado INT NOT NULL,
    tipo_operacion ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    valor_anterior JSON NULL,
    valor_nuevo JSON NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_tabla_registro (tabla_afectada, id_registro_afectado),
    INDEX idx_usuario_fecha (id_usuario, fecha)
);

CREATE TABLE asistencia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    fecha DATE NOT NULL,
    hora_entrada DATETIME NOT NULL,
    hora_salida DATETIME NULL,
    tipo_marcaje VARCHAR(15) NOT NULL,
    id_sede INT NOT NULL,
    tipo_ausencia VARCHAR(30) NULL,
    CONSTRAINT fk_asistencia_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_asistencia_sede FOREIGN KEY (id_sede) REFERENCES sede (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_asistencia_tiempos CHECK (hora_salida IS NULL OR hora_salida >= hora_entrada),
    INDEX idx_asistencia_empleado_fecha (id_empleado, fecha),
    INDEX idx_asistencia_sede (id_sede)
);

CREATE TABLE nomina (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado INT NOT NULL,
    periodo VARCHAR(15) NOT NULL,
    fecha_pago DATE NOT NULL,
    salario_bruto DECIMAL(10,2) NOT NULL,
    deduccion_tss DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    deduccion_afp DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    deduccion_isr DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    bonificaciones DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    horas_extras DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    salario_neto DECIMAL(10,2) NOT NULL,
    estado_pago ENUM('PENDIENTE','PAGADO','ANULADO') NOT NULL DEFAULT 'PENDIENTE',
    CONSTRAINT fk_nomina_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_nomina_empleado_fecha_pago UNIQUE (id_empleado, fecha_pago),
    CONSTRAINT chk_nomina_bruto CHECK (salario_bruto > 0),
    CONSTRAINT chk_nomina_neto CHECK (salario_neto >= 0),
    CONSTRAINT chk_nomina_deducciones CHECK (deduccion_tss >= 0 AND deduccion_afp >= 0 AND deduccion_isr >= 0),
    INDEX idx_nomina_empleado_periodo (id_empleado, periodo),
    INDEX idx_nomina_fecha_pago (fecha_pago),
    INDEX idx_nomina_estado (estado_pago)
);

SET FOREIGN_KEY_CHECKS = 1;
