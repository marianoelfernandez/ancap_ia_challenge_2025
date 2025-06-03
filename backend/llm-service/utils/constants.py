from langchain_core.prompts import ChatPromptTemplate

schema_constant = """
   
-- Tabla: DocCrg (Documento de Carga - Cabezal)
CREATE TABLE DocCrg (
    PlaId INT NOT NULL COMMENT 'Identificador Planta',
    DocId INT NOT NULL COMMENT 'Identificador Documento de Carga',
    DocDstId INT COMMENT 'Identificador Distribuidora',
    DocFch DATE COMMENT 'Fecha del documento (YYYYMMDD)',
    CliId INT COMMENT 'Identificador Cliente',
    CliIdDir INT COMMENT 'Identificador Dirección Cliente',
    DocNegId VARCHAR(10) COMMENT 'Identificador Negocio Cliente',
    PolId INT COMMENT 'Identificador Política',
    PRIMARY KEY (PlaId, DocId)
);

-- Tabla: DCPrdLin (Productos del Documento de Carga)
CREATE TABLE DCPrdLin (
    PlaId INT NOT NULL COMMENT 'Identificador Planta',
    DocId INT NOT NULL COMMENT 'Identificador Documento de Carga',
    PrdId INT NOT NULL COMMENT 'Identificador Producto',
    DCCntCorL DECIMAL(13,2) COMMENT 'Cantidad liquidada',
    DCCntCorUI VARCHAR(3) COMMENT 'Unidad de la cantidad liquidada',
    PRIMARY KEY (PlaId, DocId, PrdId)
);

-- Tabla: Distribuidoras
CREATE TABLE Distribuidoras (
    DstId INT NOT NULL COMMENT 'Identificador Distribuidora',
    DstNom VARCHAR(20) COMMENT 'Nombre Distribuidora',
    PRIMARY KEY (DstId)
);

-- Tabla: Plantas
CREATE TABLE Plantas (
    PlaId INT NOT NULL COMMENT 'Identificador Planta',
    PlaNom VARCHAR(25) COMMENT 'Nombre Planta',
    PRIMARY KEY (PlaId)
);

-- Tabla: Políticas
CREATE TABLE Politicas (
    PolId INT NOT NULL COMMENT 'Identificador Política',
    PolDsc VARCHAR(40) COMMENT 'Descripción Política',
    MerId INT COMMENT 'Identificador Mercado',
    PRIMARY KEY (PolId)
);

-- Tabla: Mercado
CREATE TABLE Mercado (
    MerId INT NOT NULL COMMENT 'Identificador Mercado',
    MerDsc VARCHAR(30) COMMENT 'Descripción Mercado',
    PRIMARY KEY (MerId)
);

-- Tabla: Cliente
CREATE TABLE Cliente (
    CliId INT NOT NULL COMMENT 'Identificador Cliente',
    CliNom VARCHAR(25) COMMENT 'Nombre Cliente',
    CliTpoId INT COMMENT 'Identificador Tipo Cliente',
    PRIMARY KEY (CliId)
);

-- Tabla: CliTpo (Tipo Cliente)
CREATE TABLE CliTpo (
    CliTpoId INT NOT NULL COMMENT 'Identificador Tipo Cliente',
    CliTpoDsc VARCHAR(30) COMMENT 'Descripción Tipo Cliente',
    PRIMARY KEY (CliTpoId)
);

-- Tabla: CliDir (Direcciones del Cliente)
CREATE TABLE CliDir (
    CliId INT NOT NULL COMMENT 'Identificador Cliente',
    CliIdDir INT NOT NULL COMMENT 'Identificador Dirección Cliente',
    CliDir VARCHAR(20) COMMENT 'Dirección Cliente',
    DptoId INT COMMENT 'Identificador Departamento',
    LocaliId INT COMMENT 'Identificador Localidad',
    PRIMARY KEY (CliId, CliIdDir)
);

-- Tabla: Departamento
CREATE TABLE Departamento (
    DptoId INT NOT NULL COMMENT 'Identificador Departamento',
    DptoNom VARCHAR(20) COMMENT 'Nombre Departamento',
    PRIMARY KEY (DptoId)
);

-- Tabla: Localidades
CREATE TABLE Localidades (
    DptoId INT NOT NULL COMMENT 'Identificador Departamento',
    LocaliId INT NOT NULL COMMENT 'Identificador Localidad',
    LocaliNom VARCHAR(30) COMMENT 'Nombre Localidad',
    PRIMARY KEY (DptoId, LocaliId)
);

-- Tabla: Producto
CREATE TABLE Producto (
    PrdId INT NOT NULL COMMENT 'Identificador Producto',
    PrdDsc VARCHAR(30) COMMENT 'Descripción Producto. NO ES UN NUMERO',
    PrdGrpId INT COMMENT 'Identificador Grupo Producto',
    PRIMARY KEY (PrdId)
);

-- Tabla: PrdGrp (Grupo de Productos)
CREATE TABLE PrdGrp (
    PrdGrpId INT NOT NULL COMMENT 'Identificador Grupo Producto',
    PrdGrpDsc VARCHAR(30) COMMENT 'Descripción Grupo Producto',
    PrdCatId CHAR(1) COMMENT 'Identificador Categoría Producto',
    PRIMARY KEY (PrdGrpId)
);

-- Tabla: PrdCat (Categoría de Productos)
CREATE TABLE PrdCat (
    PrdCatId CHAR(1) NOT NULL COMMENT 'Identificador Categoría Producto',
    PrdCatNom VARCHAR(15) COMMENT 'Nombre Categoría Producto',
    PRIMARY KEY (PrdCatId)
);

-- Tabla: Negocio
CREATE TABLE Negocio (
    NegId VARCHAR(10) NOT NULL COMMENT 'Identificador Negocio',
    NegDsc VARCHAR(30) COMMENT 'Descripción Negocio',
    NegTpoId INT COMMENT 'Identificador Tipo Negocio',
    PRIMARY KEY (NegId)
);

-- Tabla: NegTpo (Tipo Negocio)
CREATE TABLE NegTpo (
    NegTpoId INT NOT NULL COMMENT 'Identificador Tipo Negocio',
    NegTpoDsc VARCHAR(30) COMMENT 'Descripción Tipo Negocio',
    PRIMARY KEY (NegTpoId)
);

-- Tabla: FacCab (Factura Cabezal)
CREATE TABLE FacCab (
    FacPlaId INT NOT NULL COMMENT 'Identificador Planta',
    FacTpoDoc CHAR(1) NOT NULL COMMENT 'Tipo Factura (F: Factura, C: Nota de Crédito)',
    FacSerie CHAR(2) NOT NULL COMMENT 'Serie Factura',
    FacNro INT NOT NULL COMMENT 'Número Factura',
    FacFch DATE COMMENT 'Fecha Factura (YYYYMMDD)',
    CliId INT COMMENT 'Identificador Cliente',
    CliIdDir INT COMMENT 'Identificación Dirección Cliente',
    FacNegId VARCHAR(10) COMMENT 'Identificador Negocio Cliente',
    PolId INT COMMENT 'Identificador Política',
    DstId INT COMMENT 'Identificador Distribuidora',
    FacMonId INT COMMENT 'Identificador Moneda',
    FactTot DECIMAL(15,2) COMMENT 'Total de la Factura',
    PRIMARY KEY (FacPlaId, FacTpoDoc, FacSerie, FacNro)
);

-- Tabla: Moneda
CREATE TABLE Moneda (
    MonId VARCHAR(10) NOT NULL COMMENT 'Identificador Moneda',
    MonSig VARCHAR(4) COMMENT 'Signo Moneda',
    MonNom VARCHAR(20) COMMENT 'Nombre Moneda',
    PRIMARY KEY (MonId)
);

-- Tabla: FacLinPr (Líneas de Productos de las Facturas)
CREATE TABLE FacLinPr (
    FacPlaId INT NOT NULL COMMENT 'Identificador Planta',
    FacTpoDoc CHAR(1) NOT NULL COMMENT 'Tipo Factura (F: Factura, C: Nota de Crédito)',
    FacSerie CHAR(2) NOT NULL COMMENT 'Serie Factura',
    FacNro INT NOT NULL COMMENT 'Número Factura',
    FacLinNro INT NOT NULL COMMENT 'Número de Línea',
    PrdId INT COMMENT 'Identificador Producto',
    FacLinCnt DECIMAL(13,2) COMMENT 'Cantidad',
    FacUndFac VARCHAR(3) COMMENT 'Unidad de Facturación',
    PRIMARY KEY (FacPlaId, FacTpoDoc, FacSerie, FacNro, FacLinNro)
);

Recuerda que NO puedes calcular valores usando VARCHAR como número.
Por favor, utiliza las tablas y claves que están explícitamente definidas arriba.

"""

intent_prompt = intent_prompt = ChatPromptTemplate.from_template(
    "Given the user input below, answer with only 'SQL' or 'GENERAL'.\n"
    "Input: {query}\n"
    "Type:"
)