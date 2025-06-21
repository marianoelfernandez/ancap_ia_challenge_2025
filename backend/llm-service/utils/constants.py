from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
schema_constant = """

-- Tabla: DOCCRG (Documento de Carga - Cabezal)
-- Información general del documento de carga/entrega de productos
CREATE TABLE DOCCRG (
    PLAID INT64,              -- FK a PLANTAS(PLAID) - Identificador de la planta
    DOCID INT64,              -- Clave primaria compuesta con PLAID - Número del documento
    DOCDSTID INT64,           -- FK a DISTRIBUIDORAS(DSTID) - Distribuidora asignada
    DOCFCH DATE,              -- Fecha del documento de carga (YYYY-MM-DD)
    CLIID INT64,              -- FK a CLIENTES(CLIID) - Cliente destinatario
    CLIIDDIR INT64,           -- FK a CLIDIR(CLIIDDIR) - Dirección específica del cliente
    DOCNEGID STRING,          -- FK a NEGOCIOS(NEGID) - Tipo de negocio asociado
    POLID INT64               -- FK a POLITICAS(POLID) - Política comercial aplicada
);

-- Tabla: DCPRDLIN (Documento de Carga - Líneas de Productos)
-- Detalle de productos incluidos en cada documento de carga
CREATE TABLE DCPRDLIN (
    PLAID INT64,              -- FK a DOCCRG(PLAID) - Planta del documento
    DOCID INT64,              -- FK a DOCCRG(DOCID) - Número del documento
    PRDID INT64,              -- FK a PRODUCTOS(PRDID) - Producto entregado
    DOCCNTCORL NUMERIC,       -- Cantidad liquidada/entregada del producto
    DCCNTCORUI STRING         -- Unidad de medida de la cantidad (Kg, Lt, etc.)
);

-- Tabla: PLANTAS (Maestro de Plantas)
-- Catálogo de plantas de producción o distribución
CREATE TABLE PLANTAS (
    PLAID INT64 PRIMARY KEY,  -- Identificador único de la planta
    PLANOM STRING             -- Nombre descriptivo de la planta
);

-- Tabla: DISTRIBUIDORAS (Maestro de Distribuidoras)
-- Catálogo de empresas distribuidoras
CREATE TABLE DISTRIBUIDORAS (
    DSTID INT64 PRIMARY KEY,  -- Identificador único de la distribuidora
    DSTNOM STRING             -- Nombre de la empresa distribuidora
);

-- Tabla: POLITICAS (Maestro de Políticas Comerciales)
-- Catálogo de políticas de precios y condiciones comerciales
CREATE TABLE POLITICAS (
    POLID INT64 PRIMARY KEY,  -- Identificador único de la política
    POLDSC STRING,            -- Descripción de la política comercial
    MERID INT64               -- FK a MERCADOS(MERID) - Mercado al que aplica
);

-- Tabla: MERCADOS (Maestro de Mercados)
-- Catálogo de mercados o segmentos comerciales
CREATE TABLE MERCADOS (
    MERID INT64 PRIMARY KEY,  -- Identificador único del mercado
    MERDSC STRING             -- Descripción del mercado o segmento
);

-- Tabla: CLIENTES (Maestro de Clientes)
-- Catálogo principal de clientes
CREATE TABLE CLIENTES (
    CLIID INT64 PRIMARY KEY,  -- Identificador único del cliente
    CLINOM STRING,            -- Nombre o razón social del cliente
    CLITPOID INT64            -- FK a CLITPO(CLITPOID) - Tipo de cliente
);

-- Tabla: CLITPO (Maestro de Tipos de Cliente)
-- Clasificación de clientes por tipo o categoría
CREATE TABLE CLITPO (
    CLITPOID INT64 PRIMARY KEY, -- Identificador único del tipo de cliente
    CLITPODSC STRING            -- Descripción del tipo (Mayorista, Minorista, etc.)
);

-- Tabla: CLIDIR (Maestro de Direcciones de Clientes)
-- Direcciones de entrega de cada cliente
CREATE TABLE CLIDIR (
    CLIID NUMERIC,            -- FK a CLIENTES(CLIID) - Cliente propietario
    CLIIDDIR NUMERIC,         -- Clave primaria compuesta - ID único de dirección
    CLIDIR STRING,            -- Dirección completa de entrega
    DPTOID NUMERIC,           -- FK a DEPARTAMENTOS(DPTOID) - Departamento
    LOCALIID NUMERIC          -- FK a LOCALIDADES(LOCALIID) - Localidad específica
);

-- Tabla: DEPARTAMENTOS (Maestro de Departamentos)
-- División territorial principal (Estados/Provincias/Departamentos)
CREATE TABLE DEPARTAMENTOS (
    DPTOID NUMERIC PRIMARY KEY, -- Identificador único del departamento
    DPTONOM STRING              -- Nombre del departamento
);

-- Tabla: LOCALIDADES (Maestro de Localidades)
-- Ciudades o localidades dentro de cada departamento
CREATE TABLE LOCALIDADES (
    DPTOID NUMERIC,           -- FK a DEPARTAMENTOS(DPTOID) - Departamento padre
    LOCALIID NUMERIC,         -- Clave primaria compuesta - ID de la localidad
    LOCALINOM STRING          -- Nombre de la ciudad o localidad
);

-- Tabla: PRODUCTOS (Maestro de Productos)
-- Catálogo principal de productos comercializados
CREATE TABLE PRODUCTOS (
    PRDID NUMERIC PRIMARY KEY, -- Identificador único del producto
    PRDDSC STRING,             -- Descripción o nombre del producto
    PRDGRPID NUMERIC           -- FK a PRDGRP(PRDGRPID) - Grupo al que pertenece
);

-- Tabla: PRDGRP (Maestro de Grupos de Productos)
-- Agrupación de productos por familia o línea
CREATE TABLE PRDGRP (
    PRDGRPID NUMERIC PRIMARY KEY, -- Identificador único del grupo
    PRDGRPDSC STRING,             -- Descripción del grupo de productos
    PRDCATID STRING               -- FK a PRDCAT(PRDCATID) - Categoría superior
);

-- Tabla: PRDCAT (Maestro de Categorías de Productos)
-- Categorización de alto nivel de productos
CREATE TABLE PRDCAT (
    PRDCATID STRING PRIMARY KEY, -- Identificador de la categoría (código)
    PRDCATNOM STRING             -- Nombre descriptivo de la categoría
);

-- Tabla: NEGOCIOS (Maestro de Tipos de Negocio)
-- Clasificación de transacciones por tipo de negocio
CREATE TABLE NEGOCIOS (
    NEGID STRING PRIMARY KEY,    -- Código identificador del negocio
    NEGDSC STRING,               -- Descripción del tipo de negocio
    NEGTPOID NUMERIC             -- FK a NEGTPO(NEGTPOID) - Tipo superior de negocio
);

-- Tabla: NEGTPO (Maestro de Tipos de Negocio Superior)
-- Categorización superior de tipos de negocio
CREATE TABLE NEGTPO (
    NEGTPOID NUMERIC PRIMARY KEY, -- Identificador del tipo de negocio
    NEGTPODSC STRING              -- Descripción del tipo superior
);

-- Tabla: FACCAB (Facturas - Cabezal)
-- Información general de cada factura o documento fiscal emitido
CREATE TABLE FACCAB (
    FACPLAID NUMERIC,         -- FK a PLANTAS(PLAID) - Planta que emite la factura
    FACTPODOC STRING,         -- Tipo de documento ('F'=Factura, 'C'=Nota Crédito, etc.)
    FACNRO NUMERIC,           -- Número correlativo de factura
    FACSERIE STRING,          -- Serie del documento fiscal
    FACFCH DATE,              -- Fecha de emisión de la factura
    CLIID NUMERIC,            -- FK a CLIENTES(CLIID) - Cliente facturado
    CLIIDDIR NUMERIC,         -- FK a CLIDIR(CLIIDDIR) - Dirección de facturación
    FACNEGID STRING,          -- FK a NEGOCIOS(NEGID) - Tipo de negocio facturado
    POLID NUMERIC,            -- FK a POLITICAS(POLID) - Política comercial aplicada
    DSTID NUMERIC,            -- FK a DISTRIBUIDORAS(DSTID) - Distribuidora involucrada
    FACMONID NUMERIC,         -- FK a MONEDAS(MONID) - Moneda de la facturación
    FACTOT NUMERIC            -- Monto total de la factura
);

-- Tabla: MONEDAS (Maestro de Monedas)
-- Catálogo de monedas para facturación multimoneda
CREATE TABLE MONEDAS (
    MONID NUMERIC PRIMARY KEY,   -- Identificador único de la moneda
    MONSIG STRING,               -- Símbolo de la moneda ($, €, etc.)
    MONNOM STRING                -- Nombre completo de la moneda
);

-- Tabla: FACLINPR (Facturas - Líneas de Productos)
-- Detalle de productos incluidos en cada factura
CREATE TABLE FACLINPR (
    FACPLAID NUMERIC,         -- FK a FACCAB(FACPLAID) - Planta de la factura
    FACTPODOC STRING,         -- FK a FACCAB(FACTPODOC) - Tipo de documento
    FACNRO NUMERIC,           -- FK a FACCAB(FACNRO) - Número de factura
    FACSERIE STRING,          -- FK a FACCAB(FACSERIE) - Serie del documento
    FACLINNRO NUMERIC,        -- Número de línea dentro de la factura
    PRDID NUMERIC,            -- FK a PRODUCTOS(PRDID) - Producto facturado
    FACLINCNT NUMERIC,        -- Cantidad facturada del producto
    FACUNDFAC STRING          -- Unidad de medida facturada
);

Recuerda que NO puedes calcular valores usando VARCHAR como número.
Por favor, utiliza las tablas y claves que están explícitamente definidas arriba.
Todas las tablas estan en la base de datos "datosancap.entregas_facturacion", por lo que debes usar el nombre de la tabla y no el nombre del esquema.
Ejemplo: no uses "FACCAB" y usa "datosancap.entregas_facturacion.FACCAB" para referirte a la tabla de facturas.

"""

#TODO: Ver de pasar o al agente o a dataservice el projectId y tableId (ancap-equipo2.testing)
intent_prompt = ChatPromptTemplate.from_messages([
    ("system", 
     "Dada una pregunta de un usuario, debes identificar si requiere una consulta SQL o solo es una conversación. "
     "Responde SOLO 'SQL' si la intención del usuario es una consulta a base de datos o 'GENERAL'."),
    ("system", "Usa la siguiente memoria de la conversacion:"), 
    MessagesPlaceholder("chat_history"),
    ("user", "User: {query}\nTipo:")
])

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

FacMonId (INT), FacTot (DECIMAL)
PK: (FacPlaId, FacTpoDoc, FacSerie, FacNro)

Moneda

MonId (VARCHAR), MonSig (VARCHAR), MonNom (VARCHAR)
PK: MonId

FacLinPr (Líneas de Productos Factura)

FacPlaId, FacTpoDoc, FacSerie, FacNro, FacLinNro (Clave compuesta)

PrdId (INT), FacLinCnt (DECIMAL), FacUndFac (VARCHAR)
PK: (FacPlaId, FacTpoDoc, FacSerie, FacNro, FacLinNro)

"""
data_dictionary_incomplete_prompt = ChatPromptTemplate.from_messages([
    """Eres un experto en diccionario de datos, usa el diccionario de datos para traducir la pregunta del usuario a una
      pregunta curada con información específica sobre las tablas a consultar, generalmente son sobre el sistema de entregas o de facturas. Debes REESCRIBIR la consulta del usuario EN LENGUAJE NATURAL para que sea más descriptiva, sin agregar preguntas para el usuario.
      Responde SOLO con la consulta transformada o una solicitud de más información comenzando con [RETRY] seguido de una pregunta sobre la inforacion ambigua o casos en donde la pregunta no haga referencia a ninguna tabla.
      NO fuerces al usuario a realizar un filtro por fechas\n\n""",
    ("system", "Usa el siguiente diccionario de datos para responder a las preguntas del usuario: {data_dictionary}"),
    "Este es el historial de mensajes previos:",MessagesPlaceholder("chat_history"),
    "Input: {query}\n"])


data_dictionary_prompt = data_dictionary_incomplete_prompt.partial(data_dictionary=data_dictionary)
facturas_tables = [
    "FACCAB",        # Facturas - cabezal
    "FACLINPR",      # Facturas - productos
    "MONEDAS",       # Maestro Monedas
    "CLIENTES",      # Maestro Clientes
    "CLIDIR",        # Direcciones de Clientes
    "DISTRIBUIDORAS",# Maestro Distribuidoras
    "PLANTAS",       # Maestro Plantas
    "POLITICAS",     # Maestro Políticas
    "MERCADOS",      # Maestro Mercados
    "NEGOCIOS",      # Maestro Negocios
    "NEGTPO",        # Maestro Tipos de Negocios
    "CLITPO",        # Maestro Tipos de Cliente
    "PRODUCTOS",     # Maestro Productos
    "PRDGRP",        # Grupos de Productos
    "PRDCAT",        # Categorías de Productos
    "DEPARTAMENTOS", # Maestro Departamentos
    "LOCALIDADES"    # Maestro Localidades
]
entregas_tables = [
    "DOCCRG",        # Documento de Carga - cabezal
    "DCPRDLIN",      # Documento de Carga - productos
    "CLIENTES",      # Maestro Clientes
    "CLIDIR",        # Direcciones de Clientes
    "DISTRIBUIDORAS",# Maestro Distribuidoras
    "PLANTAS",       # Maestro Plantas
    "POLITICAS",     # Maestro Políticas
    "MERCADOS",      # Maestro Mercados
    "NEGOCIOS",      # Maestro Negocios
    "NEGTPO",        # Maestro Tipos de Negocios
    "CLITPO",        # Maestro Tipos de Cliente
    "PRODUCTOS",     # Maestro Productos
    "PRDGRP",        # Grupos de Productos
    "PRDCAT",        # Categorías de Productos
    "DEPARTAMENTOS", # Maestro Departamentos
    "LOCALIDADES"    # Maestro Localidades
]
