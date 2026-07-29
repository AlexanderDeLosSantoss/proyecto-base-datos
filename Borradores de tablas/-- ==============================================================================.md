-- ==============================================================================  
-- PROYECTO: Base de Datos de Recursos Humanos (ITN)  
-- RESPONSABLE: Allan  
-- FASE: Día 4 - Diseño Físico (MySQL) - Tablas: asistencia y nomina  
-- ==============================================================================  
  
-- ------------------------------------------------------------------------------  
-- 1. TABLA: asistencia  
-- Descripción: Registra las marcaciones diarias y ausencias de los empleados.  
-- ------------------------------------------------------------------------------  
CREATE TABLE asistencia (  
    ID INT AUTO_INCREMENT NOT NULL,  
    ID_EMPLEADO INT NOT NULL,  
    FECHA DATE NOT NULL,  
    HORA_ENTRADA DATETIME NOT NULL,  
    HORA_SALIDA DATETIME NULL,  
    TIPO_MARCAJE VARCHAR(15) NOT NULL, -- Valores: 'ENTRADA', 'SALIDA'  
    ID_SEDE INT NOT NULL, -- Sede física donde ocurrió el marcaje  
    TIPO_AUSENCIA VARCHAR(30) NULL, -- Valores: 'JUSTIFICADA', 'INJUSTIFICADA', 'MEDICA', 'NULA'  
      
    -- Clave Primaria  
    CONSTRAINT pk_asistencia PRIMARY KEY (ID),  
      
    -- Claves Foráneas  
    CONSTRAINT fk_asistencia_empleado FOREIGN KEY (ID_EMPLEADO)   
        REFERENCES empleado(ID) ON DELETE RESTRICT ON UPDATE CASCADE,  
    CONSTRAINT fk_asistencia_sede FOREIGN KEY (ID_SEDE)   
        REFERENCES sede(ID) ON DELETE RESTRICT ON UPDATE CASCADE,  
          
    -- Restricciones de Integridad (Constraints)  
    -- Garantiza que si hay hora de salida, esta sea posterior a la entrada  
    CONSTRAINT chk_asistencia_tiempos CHECK (HORA_SALIDA IS NULL OR HORA_SALIDA >= HORA_ENTRADA)  
);  
  
-- Índices para optimizar búsquedas comunes  
CREATE INDEX idx_asistencia_empleado_fecha ON asistencia(ID_EMPLEADO, FECHA);  
CREATE INDEX idx_asistencia_sede ON asistencia(ID_SEDE);  
  
  
-- ------------------------------------------------------------------------------  
-- 2. TABLA: nomina  
-- Descripción: Almacena los registros de pago, deducciones y estado salarial.  
-- ------------------------------------------------------------------------------  
CREATE TABLE nomina (  
    ID INT AUTO_INCREMENT NOT NULL,  
    ID_EMPLEADO INT NOT NULL,  
    PERIODO VARCHAR(15) NOT NULL, -- Valores: 'MENSUAL', 'QUINCENAL'  
    FECHA_PAGO DATE NOT NULL,  
    SALARIO_BRUTO DECIMAL(10,2) NOT NULL,  
    DEDUCCION_TSS DECIMAL(10,2) NOT NULL DEFAULT 0.00,  
    DEDUCCION_AFP DECIMAL(10,2) NOT NULL DEFAULT 0.00,  
    DEDUCCION_ISR DECIMAL(10,2) NOT NULL DEFAULT 0.00,  
    BONIFICACIONES DECIMAL(10,2) NOT NULL DEFAULT 0.00,  
    HORAS_EXTRAS DECIMAL(10,2) NOT NULL DEFAULT 0.00,  
    SALARIO_NETO DECIMAL(10,2) NOT NULL,  
    ESTADO_PAGO VARCHAR(20) NOT NULL, -- Valores: 'PROCESANDO', 'PENDIENTE', 'PAGADO'  
      
    -- Clave Primaria  
    CONSTRAINT pk_nomina PRIMARY KEY (ID),  
      
    -- Claves Foráneas  
    CONSTRAINT fk_nomina_empleado FOREIGN KEY (ID_EMPLEADO)   
        REFERENCES empleado(ID) ON DELETE RESTRICT ON UPDATE CASCADE,  
          
    -- Restricciones de Integridad (Constraints)  
    CONSTRAINT chk_nomina_bruto CHECK (SALARIO_BRUTO > 0),  
    CONSTRAINT chk_nomina_neto CHECK (SALARIO_NETO >= 0),  
    CONSTRAINT chk_nomina_deducciones CHECK (  
        DEDUCCION_TSS >= 0 AND   
        DEDUCCION_AFP >= 0 AND   
        DEDUCCION_ISR >= 0  
    )  
);  
  
-- Índices para optimizar búsquedas comunes y reportes financieros  
CREATE INDEX idx_nomina_empleado_periodo ON nomina(ID_EMPLEADO, PERIODO);  
CREATE INDEX idx_nomina_fecha_pago ON nomina(FECHA_PAGO);  
CREATE INDEX idx_nomina_estado ON nomina(ESTADO_PAGO);  
