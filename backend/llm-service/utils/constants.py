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

-- Tabla: houses_data
CREATE TABLE ancap-equipo2.testing.houses_data (
    id INTEGER,
    date DATE,
    bedrooms VARCHAR(255),
    bathrooms VARCHAR(255),
    square_footage_living VARCHAR(255),
    floors VARCHAR(255),
    waterfront VARCHAR(255),
    view VARCHAR(255),
    condition VARCHAR(255),
    grade VARCHAR(255),
    square_footage_above VARCHAR(255),
    square_footage_basement VARCHAR(255),
    year_built VARCHAR(255),
    year_renovated VARCHAR(255),
    zipcode VARCHAR(255),
    lat VARCHAR(255),
    long FLOAT,
    price INTEGER
);

Recuerda que NO puedes calcular valores usando VARCHAR como número.
Por favor, utiliza las tablas y claves que están explícitamente definidas arriba.

"""

#TODO: Ver de pasar o al agente o a dataservice el projectId y tableId (ancap-equipo2.testing)

intent_prompt = ChatPromptTemplate.from_template(
    "Given the user input below, answer with only 'SQL' or 'GENERAL'.\n"
    "Input: {query}\n"
    "Type:"
)

data_dictionary = """
Diccionario de Datos

DocCrg (Documento de Carga - Cabezal)
Campos:

PlaId (INT): Planta

DocId (INT): Documento de Carga

DocDstId (INT): Distribuidora

DocFch (DATE): Fecha

CliId (INT): Cliente

CliIdDir (INT): Dirección Cliente

DocNegId (VARCHAR): Negocio Cliente

PolId (INT): Política
PK: (PlaId, DocId)

DCPrdLin (Productos del Documento de Carga)
Campos:

PlaId, DocId, PrdId (INT): Claves

DCCntCorL (DECIMAL): Cantidad

DCCntCorUI (VARCHAR): Unidad
PK: (PlaId, DocId, PrdId)

Distribuidoras

DstId (INT), DstNom (VARCHAR)
PK: DstId

Plantas

PlaId (INT), PlaNom (VARCHAR)
PK: PlaId

Politicas

PolId (INT), PolDsc (VARCHAR), MerId (INT)
PK: PolId

Mercado

MerId (INT), MerDsc (VARCHAR)
PK: MerId

Cliente

CliId (INT), CliNom (VARCHAR), CliTpoId (INT)
PK: CliId

CliTpo (Tipo Cliente)

CliTpoId (INT), CliTpoDsc (VARCHAR)
PK: CliTpoId

CliDir (Direcciones del Cliente)

CliId, CliIdDir (INT), CliDir (VARCHAR), DptoId, LocaliId (INT)
PK: (CliId, CliIdDir)

Departamento

DptoId (INT), DptoNom (VARCHAR)
PK: DptoId

Localidades

DptoId, LocaliId (INT), LocaliNom (VARCHAR)
PK: (DptoId, LocaliId)

Producto

PrdId (INT), PrdDsc (VARCHAR), PrdGrpId (INT)
PK: PrdId

PrdGrp (Grupo de Productos)

PrdGrpId (INT), PrdGrpDsc (VARCHAR), PrdCatId (CHAR)
PK: PrdGrpId

PrdCat (Categoría Productos)

PrdCatId (CHAR), PrdCatNom (VARCHAR)
PK: PrdCatId

Negocio

NegId (VARCHAR), NegDsc (VARCHAR), NegTpoId (INT)
PK: NegId

NegTpo (Tipo Negocio)

NegTpoId (INT), NegTpoDsc (VARCHAR)
PK: NegTpoId

FacCab (Factura Cabezal)
Campos:

FacPlaId (INT), FacTpoDoc (CHAR), FacSerie (CHAR), FacNro (INT)

FacFch (DATE), CliId, CliIdDir, FacNegId, PolId, DstId (INT)

FacMonId (INT), FactTot (DECIMAL)
PK: (FacPlaId, FacTpoDoc, FacSerie, FacNro)

Moneda

MonId (VARCHAR), MonSig (VARCHAR), MonNom (VARCHAR)
PK: MonId

FacLinPr (Líneas de Productos Factura)

FacPlaId, FacTpoDoc, FacSerie, FacNro, FacLinNro (Clave compuesta)

PrdId (INT), FacLinCnt (DECIMAL), FacUndFac (VARCHAR)
PK: (FacPlaId, FacTpoDoc, FacSerie, FacNro, FacLinNro)

houses_data

id (INT), date (DATE), price (INT)

bedrooms, bathrooms, square_footage_living, floors, waterfront, view, condition, grade, square_footage_above, square_footage_basement, year_built, year_renovated, zipcode, lat (VARCHAR), long (FLOAT)
"""
data_dictionary_incomplete_prompt = ChatPromptTemplate.from_template(
    """Eres un experto en diccionario de datos, usa el diccionario de datos para traducir la pregunta del usuario a una
      pregunta curada con información específica sobre las tablas a consultar. Responde SOLO con la pregunta curada o una solicitud de más 
      información comenzando con [RETRY].\n\n"""
    "{data_dictionary}\n\n"
    "Input: {query}\n"
    "Type:"
)


data_dictionary_prompt = data_dictionary_incomplete_prompt.partial(data_dictionary=data_dictionary)