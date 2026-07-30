-- =========================================
-- TABLA: empleado
-- Responsable: Ivan
-- =========================================
CREATE TABLE empleado (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    nombre             VARCHAR(150)   NOT NULL,
    cedula             VARCHAR(20)    NOT NULL,
    fecha_nacimiento   DATE           NOT NULL,
    telefono           VARCHAR(20)    NULL,
    genero             ENUM('M','F','OTRO') NULL,
    direccion          VARCHAR(255)   NULL,
    email              VARCHAR(150)   NULL,
    fecha_ingreso      DATE           NOT NULL,
    estado             ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    id_departamento    INT            NOT NULL,
    id_puesto          INT            NOT NULL,
    id_sede            INT            NOT NULL,
    salario_actual     DECIMAL(10,2)  NOT NULL,
    datos_bancarios    VARCHAR(255)   NULL,

    CONSTRAINT uq_empleado_cedula UNIQUE (cedula),
    CONSTRAINT uq_empleado_email  UNIQUE (email),

    CONSTRAINT chk_empleado_salario CHECK (salario_actual >= 0),
    CONSTRAINT chk_empleado_fechas CHECK (fecha_ingreso >= fecha_nacimiento),

    CONSTRAINT fk_empleado_departamento
        FOREIGN KEY (id_departamento) REFERENCES departamento(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_empleado_puesto
        FOREIGN KEY (id_puesto) REFERENCES puesto(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_empleado_sede
        FOREIGN KEY (id_sede) REFERENCES sede(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    INDEX idx_empleado_departamento (id_departamento),
    INDEX idx_empleado_puesto (id_puesto),
    INDEX idx_empleado_sede (id_sede),
    INDEX idx_empleado_estado (estado),
    INDEX idx_empleado_nombre (nombre)
);

-- =========================================
-- TABLA: contrato
-- Responsable: Ivan
-- =========================================
CREATE TABLE contrato (
    id                    INT AUTO_INCREMENT PRIMARY KEY,
    id_empleado           INT            NOT NULL,
    id_puesto             INT            NOT NULL,
    id_departamento       INT            NOT NULL,
    tipo_contrato         VARCHAR(50)    NOT NULL,
    fecha_inicio          DATE           NOT NULL,
    fecha_fin             DATE           NULL,
    salario_pactado       DECIMAL(10,2)  NOT NULL,
    estado                ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    motivo_finalizacion   VARCHAR(255)   NULL,

    CONSTRAINT chk_contrato_salario CHECK (salario_pactado >= 0),
    CONSTRAINT chk_contrato_fechas  CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),

    CONSTRAINT fk_contrato_empleado
        FOREIGN KEY (id_empleado) REFERENCES empleado(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_contrato_puesto
        FOREIGN KEY (id_puesto) REFERENCES puesto(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    CONSTRAINT fk_contrato_departamento
        FOREIGN KEY (id_departamento) REFERENCES departamento(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    INDEX idx_contrato_empleado (id_empleado),
    INDEX idx_contrato_estado (estado),
    INDEX idx_contrato_fechas (fecha_inicio, fecha_fin)
);
