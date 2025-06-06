from langchain_core.prompts import ChatPromptTemplate

schema_constant = """

-- Tabla: DOCCRG (Documento de Carga - Cabezal)
-- Información general del documento de carga
CREATE TABLE DOCCRG (
    PlaId INTEGER,            -- FK a PLANTAS(PlaId)
    DocId INTEGER,            -- Clave primaria compuesta con PlaId
    DocDstId INTEGER,         -- FK a DISTRIBUIDORAS(DstId)
    DocFch DATE,              -- Fecha del documento (YYYY-MM-DD)
    CliId INTEGER,            -- FK a CLIENTES(CliId)
    CliIdDir INTEGER,         -- FK a CLIDIR(CliIdDir)
    DocNegId TEXT,            -- FK a NEGOCIOS(NegId)
    PolId INTEGER             -- FK a POLITICAS(PolId)
);

-- Tabla: DCPRDLIN (Documento de Carga - Productos)
-- Detalle de productos en cada documento de carga
CREATE TABLE DCPRDLIN (
    PlaId INTEGER,            -- FK a DOCCRG(PlaId)
    DocId INTEGER,            -- FK a DOCCRG(DocId)
    PrdId INTEGER,            -- FK a PRODUCTOS(PrdId)
    DCCntCorL NUMERIC,        -- Cantidad liquidada
    DCCntCorUI TEXT           -- Unidad de cantidad liquidada
);

-- Tabla: DISTRIBUIDORAS (Maestro de Distribuidoras)
CREATE TABLE DISTRIBUIDORAS (
    DstId INTEGER PRIMARY KEY,
    DstNom TEXT
);

-- Tabla: PLANTAS (Maestro de Plantas)
CREATE TABLE PLANTAS (
    PlaId INTEGER PRIMARY KEY,
    PlaNom TEXT
);

-- Tabla: POLITICAS (Maestro de Políticas)
CREATE TABLE POLITICAS (
    PolId INTEGER PRIMARY KEY,
    PolDsc TEXT,
    MerId INTEGER             -- FK a MERCADOS(MerId)
);

-- Tabla: MERCADOS (Maestro de Mercados)
CREATE TABLE MERCADOS (
    MerId INTEGER PRIMARY KEY,
    MerDsc TEXT
);

-- Tabla: CLIENTES (Maestro de Clientes)
CREATE TABLE CLIENTES (
    CliId INTEGER PRIMARY KEY,
    CliNom TEXT,
    CliTpoId INTEGER          -- FK a CLITPO(CliTpoId)
);

-- Tabla: CLITPO (Maestro de Tipos de Cliente)
CREATE TABLE CLITPO (
    CliTpoId INTEGER PRIMARY KEY,
    CliTpoDsc TEXT
);

-- Tabla: CLIDIR (Maestro de Direcciones de Clientes)
CREATE TABLE CLIDIR (
    CliId NUMERIC,            -- FK a CLIENTES(CliId)
    CliIdDir NUMERIC,         -- Clave primaria compuesta con CliId
    CliDir TEXT,
    DptoId NUMERIC,           -- FK a DEPARTAMENTOS(DptoId)
    LocaliId NUMERIC          -- FK a LOCALIDADES(LocaliId)
);

-- Tabla: DEPARTAMENTOS (Maestro de Departamentos)
CREATE TABLE DEPARTAMENTOS (
    DptoId NUMERIC PRIMARY KEY,
    DptoNom TEXT
);

-- Tabla: LOCALIDADES (Maestro de Localidades)
CREATE TABLE LOCALIDADES (
    DptoId NUMERIC,           -- FK a DEPARTAMENTOS(DptoId)
    LocaliId NUMERIC,         -- Clave primaria compuesta con DptoId
    LocaliNom TEXT
);

-- Tabla: PRODUCTOS (Maestro de Productos)
CREATE TABLE PRODUCTOS (
    PrdId NUMERIC PRIMARY KEY,
    PrdDsc TEXT,
    PrdGrpId NUMERIC          -- FK a PRDGRP(PrdGrpId)
);

-- Tabla: PRDGRP (Maestro de Grupos de Productos)
CREATE TABLE PRDGRP (
    PrdGrpId NUMERIC PRIMARY KEY,
    PrdGrpDsc TEXT,
    PrdCatId TEXT             -- FK a PRDCAT(PrdCatId)
);

-- Tabla: PRDCAT (Maestro de Categorías de Productos)
CREATE TABLE PRDCAT (
    PrdCatId TEXT PRIMARY KEY,
    PrdCatNom TEXT
);

-- Tabla: NEGOCIOS (Maestro de Negocios)
CREATE TABLE NEGOCIOS (
    NegId TEXT PRIMARY KEY,
    NegDsc TEXT,
    NegTpoId NUMERIC          -- FK a NEGTPO(NegTpoId)
);

-- Tabla: NEGTPO (Maestro de Tipos de Negocios)
CREATE TABLE NEGTPO (
    NegTpoId NUMERIC PRIMARY KEY,
    NegTpoDsc TEXT
);

-- Tabla: FACCAB (Facturas - Cabezal)
-- Información general de cada factura emitida
CREATE TABLE FACCAB (
    FacPlaId NUMERIC,         -- FK a PLANTAS(PlaId)
    FacTpoDoc TEXT,           -- Tipo de factura ('F' Factura, 'C' Nota de Crédito)
    FacSerie TEXT,
    FacNro NUMERIC,           -- Clave primaria compuesta con PlaId, TpoDoc, Serie, Nro
    FacFch DATE,
    CliId NUMERIC,            -- FK a CLIENTES(CliId)
    CliIdDir NUMERIC,         -- FK a CLIDIR(CliIdDir)
    FacNegId TEXT,            -- FK a NEGOCIOS(NegId)
    PolId NUMERIC,            -- FK a POLITICAS(PolId)
    DstId NUMERIC,            -- FK a DISTRIBUIDORAS(DstId)
    FacMonId NUMERIC,         -- FK a MONEDAS(MonId)
    FactTot NUMERIC
);

-- Tabla: MONEDAS (Maestro de Monedas)
CREATE TABLE MONEDAS (
    MonId NUMERIC PRIMARY KEY,
    MonSig TEXT,
    MonNom TEXT
);

-- Tabla: FACLINPR (Facturas - Productos)
-- Detalle de productos facturados
CREATE TABLE FACLINPR (
    FacPlaId NUMERIC,         -- FK a FACCAB(FacPlaId)
    FacTpoDoc TEXT,           -- FK a FACCAB(FacTpoDoc)
    FacSerie TEXT,            -- FK a FACCAB(FacSerie)
    FacNro NUMERIC,           -- FK a FACCAB(FacNro)
    FacLinNro NUMERIC,
    PrdId NUMERIC,            -- FK a PRODUCTOS(PrdId)
    FacLinCnt NUMERIC,
    FacUndFac TEXT
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