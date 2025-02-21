-- Crear BD
CREATE DATABASE SistemaSanitario;
GO

USE SistemaSanitario;
GO

-- Crear tabla HOSPITAL
CREATE TABLE HOSPITAL (
    codHospital VARCHAR(10) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) NOT NULL
);

-- Crear tabla SERVICIO
CREATE TABLE SERVICIO (
    idServicio VARCHAR(10) PRIMARY KEY,
    nombreCompleto VARCHAR(100) NOT NULL,
    comentarios VARCHAR(500) NULL
);

-- Crear tabla MEDICO
CREATE TABLE MEDICO (
    idMedico VARCHAR(10) PRIMARY KEY,
    nombres VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL,
    fechaNacimiento DATE NOT NULL,
    hospitalAsignado VARCHAR(10) NOT NULL,
    esDirector BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Medico_Hospital FOREIGN KEY (hospitalAsignado)
        REFERENCES HOSPITAL(codHospital)
);

-- Agregar restricción para Director del Hospital
ALTER TABLE HOSPITAL
ADD idDirector VARCHAR(10) NULL,
CONSTRAINT FK_Director_Hospital FOREIGN KEY (idDirector)
    REFERENCES MEDICO(idMedico);

-- Crear tabla SERVICIO_DISPONIBLE
CREATE TABLE SERVICIO_DISPONIBLE (
    codHospital VARCHAR(10),
    idServicio VARCHAR(10),
    cantCamas INT NULL,
    PRIMARY KEY (codHospital, idServicio),
    CONSTRAINT FK_Servicios_Hospital FOREIGN KEY (codHospital)
        REFERENCES HOSPITAL(codHospital),
    CONSTRAINT FK_Servicio_Disponible FOREIGN KEY (idServicio)
        REFERENCES SERVICIO(idServicio),
    CONSTRAINT CHK_cantCamas CHECK (cantCamas >= 0)
);

-- Crear tabla SERVICIO_MEDICO
CREATE TABLE SERVICIO_MEDICO (
    idMedico VARCHAR(10),
    codHospital VARCHAR(10),
    idServicio VARCHAR(10),
    PRIMARY KEY (idMedico, codHospital, idServicio),
    CONSTRAINT FK_ServicioMedico_Medico FOREIGN KEY (idMedico)
        REFERENCES MEDICO(idMedico),
    CONSTRAINT FK_ServicioMedico_Hospital FOREIGN KEY (codHospital)
        REFERENCES HOSPITAL(codHospital),
    CONSTRAINT FK_ServicioMedico_Servicio FOREIGN KEY (idServicio)
        REFERENCES SERVICIO(idServicio)
);

-- Crear tabla PACIENTE
CREATE TABLE PACIENTE (
    idPaciente VARCHAR(10) PRIMARY KEY,
    nombres VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL,
    fechaNacimiento DATE NOT NULL,
    numeroSeguridadSocial VARCHAR(20) NOT NULL UNIQUE,
    direccion VARCHAR(500) NULL
);

-- Crear tabla HISTORIA_CLINICA
CREATE TABLE HISTORIA_CLINICA (
    codHist VARCHAR(10) PRIMARY KEY,
    idPaciente VARCHAR(10) NOT NULL UNIQUE,
    CONSTRAINT FK_HistoriaClinica_Paciente FOREIGN KEY (idPaciente)
        REFERENCES PACIENTE(idPaciente)
);

-- Crear tabla VISITA
CREATE TABLE VISITA (
    idVisita VARCHAR(10) PRIMARY KEY,
    codHist VARCHAR(10) NOT NULL,
    fechaVisita DATETIME NOT NULL,
    idMedico VARCHAR(10) NOT NULL,
    codHospital VARCHAR(10) NOT NULL,
    idServicio VARCHAR(10) NOT NULL,
    diagnostico VARCHAR(500) NOT NULL,
    tratamiento VARCHAR(500) NOT NULL,
    numHabitacion VARCHAR(10) NULL,
    fechaDadoDeAlta DATE NULL,
    CONSTRAINT FK_Visita_HistoriaClinica FOREIGN KEY (codHist)
        REFERENCES HISTORIA_CLINICA(codHist),
    CONSTRAINT FK_Visita_Medico FOREIGN KEY (idMedico)
        REFERENCES MEDICO(idMedico),
    CONSTRAINT FK_Visita_Hospital FOREIGN KEY (codHospital)
        REFERENCES HOSPITAL(codHospital),
    CONSTRAINT FK_Visita_Servicio FOREIGN KEY (idServicio)
        REFERENCES SERVICIO(idServicio),
    CONSTRAINT CHK_fechaDadoAlta CHECK (fechaDadoAlta IS NULL OR fechaDadoAlta >= CAST(fechaVisita AS DATE))
);

-- Creación de Index para mejor rendimiento
CREATE INDEX IX_HospitalAsignado_Medico ON MEDICO(hospitalAsignado);
CREATE INDEX IX_Fecha_visita ON VISITA(fechaVisita);
CREATE INDEX IX_Visita_Hospital_Servicio ON VISITA(codHospital, idServicio);
CREATE INDEX IX_ServicioDisponible_Hospital ON SERVICIO_DISPONIBLE(codHospital);
CREATE INDEX IX_Paciente_HistoriaClinica ON HISTORIA_CLINICA(idPaciente);

-- Creación de View para ver la disponibilidad de camas
PRINT 'Creando VIEW para ver disponibilidad de camas'
GO

CREATE VIEW VW_CamasDisponibles AS
SELECT 
    h.nombre AS NombreHospital,
    s.nombreCompleto AS NombreServicio,
    sd.cantCamas AS TotalCamas,
    (sd.cantCamas - COALESCE(
        (SELECT COUNT(*)
         FROM VISITA v
         WHERE v.codHospital = h.codHospital
         AND v.idServicio = s.idServicio
         AND v.numHabitacion IS NOT NULL
         AND v.fechaDadoAlta IS NULL), 0
    )) AS CamasDisponibles
FROM HOSPITAL h
JOIN SERVICIO_DISPONIBLE sd ON h.codHospital = sd.codHospital
JOIN SERVICIO s ON sd.idServicio = s.idServicio
WHERE sd.cantCamas IS NOT NULL;
