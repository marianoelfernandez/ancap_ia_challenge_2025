import asyncio
import json
import logging
import os
import re
import shutil
from typing import Dict, List, Optional, Any

import requests
from dotenv import load_dotenv
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


class Configuration:
    """Manages configuration and environment variables for the MCP client."""

    def __init__(self) -> None:
        """Initialize configuration with environment variables."""
        self.load_env()
        self.api_key = os.getenv("GROQ_API_KEY")
        # self.api_key = os.getenv("GITHUB_API_KEY")

    @staticmethod
    def load_env() -> None:
        """Load environment variables from .env file."""
        load_dotenv()

    @staticmethod
    def load_config(file_path: str) -> Dict[str, Any]:
        """Load server configuration from JSON file.
        
        Args:
            file_path: Path to the JSON configuration file.
            
        Returns:
            Dict containing server configuration.
            
        Raises:
            FileNotFoundError: If configuration file doesn't exist.
            JSONDecodeError: If configuration file is invalid JSON.
        """
        with open(file_path, 'r') as f:
            return json.load(f)

    @property
    def llm_api_key(self) -> str:
        """Get the LLM API key.
        
        Returns:
            The API key as a string.
            
        Raises:
            ValueError: If the API key is not found in environment variables.
        """
        self.api_key= os.getenv("LLM_API_KEY")
        if not self.api_key:
            raise ValueError("LLM_API_KEY not found in environment variables")
        return self.api_key


class Server:
    """Manages MCP server connections and tool execution."""

    def __init__(self, name: str, config: Dict[str, Any]) -> None:
        self.name: str = name
        self.config: Dict[str, Any] = config
        self.stdio_context: Optional[Any] = None
        self.session: Optional[ClientSession] = None
        self._cleanup_lock: asyncio.Lock = asyncio.Lock()
        self.capabilities: Optional[Dict[str, Any]] = None

    async def initialize(self) -> None:
        """Initialize the server connection."""
        server_params = StdioServerParameters(
            command=shutil.which("npx") if self.config['command'] == "npx" else self.config['command'],
            args=self.config['args'],
            env={**os.environ, **self.config['env']} if self.config.get('env') else None
        )
        try:
            self.stdio_context = stdio_client(server_params)
            read, write = await self.stdio_context.__aenter__()
            self.session = ClientSession(read, write)
            await self.session.__aenter__()
            self.capabilities = await self.session.initialize()
        except Exception as e:
            logging.error(f"Error initializing server {self.name}: {e}")
            await self.cleanup()
            raise

    async def list_tools(self) -> List[Any]:
        """List available tools from the server.
        
        Returns:
            A list of available tools.
            
        Raises:
            RuntimeError: If the server is not initialized.
        """
        if not self.session:
            raise RuntimeError(f"Server {self.name} not initialized")
        
        tools_response = await self.session.list_tools()
        tools = []
        
        supports_progress = (
            self.capabilities 
            and 'progress' in self.capabilities
        )
        
        if supports_progress:
            logging.info(f"Server {self.name} supports progress tracking")
        
        for item in tools_response:
            if isinstance(item, tuple) and item[0] == 'tools':
                for tool in item[1]:
                    tools.append(Tool(tool.name, tool.description, tool.inputSchema))
                    if supports_progress:
                        logging.info(f"Tool '{tool.name}' will support progress tracking")
        
        return tools

    async def execute_tool(
        self, 
        tool_name: str, 
        arguments: Dict[str, Any], 
        retries: int = 2, 
        delay: float = 1.0
    ) -> Any:
        """Execute a tool with retry mechanism.
        
        Args:
            tool_name: Name of the tool to execute.
            arguments: Tool arguments.
            retries: Number of retry attempts.
            delay: Delay between retries in seconds.
            
        Returns:
            Tool execution result.
            
        Raises:
            RuntimeError: If server is not initialized.
            Exception: If tool execution fails after all retries.
        """
        if not self.session:
            raise RuntimeError(f"Server {self.name} not initialized")

        attempt = 0

        while attempt < retries:
            try:
                supports_progress = (
                    self.capabilities 
                    and 'progress' in self.capabilities
                )

                if supports_progress:
                    logging.info(f"Executing {tool_name} with progress tracking...")
                    result = await self.session.call_tool(
                        tool_name, 
                        arguments,
                        progress_token=f"{tool_name}_execution"
                    )
                else:
                    logging.info(f"Executing {tool_name}...")
                    result = await self.session.call_tool(tool_name, arguments)
                return result

            except Exception as e:
                attempt += 1
                logging.warning(f"Error executing tool: {e}. Attempt {attempt} of {retries}.")
                if attempt < retries:
                    logging.info(f"Retrying in {delay} seconds...")
                    await asyncio.sleep(delay)
                else:
                    logging.error("Max retries reached. Failing.")
                    raise

    async def cleanup(self) -> None:
        """Clean up server resources."""
        async with self._cleanup_lock:
            try:
                if self.session:
                    try:
                        await self.session.__aexit__(None, None, None)
                    except Exception as e:
                        logging.warning(f"Warning during session cleanup for {self.name}: {e}")
                    finally:
                        self.session = None

                if self.stdio_context:
                    try:
                        await self.stdio_context.__aexit__(None, None, None)
                    except (RuntimeError, asyncio.CancelledError) as e:
                        logging.info(f"Note: Normal shutdown message for {self.name}: {e}")
                    except Exception as e:
                        logging.warning(f"Warning during stdio cleanup for {self.name}: {e}")
                    finally:
                        self.stdio_context = None
            except Exception as e:
                logging.error(f"Error during cleanup of server {self.name}: {e}")


class Tool:
    """Represents a tool with its properties and formatting."""

    def __init__(self, name: str, description: str, input_schema: Dict[str, Any]) -> None:
        self.name: str = name
        self.description: str = description
        self.input_schema: Dict[str, Any] = input_schema

    def format_for_llm(self) -> str:
        """Format tool information for LLM.
        
        Returns:
            A formatted string describing the tool.
        """
        args_desc = []
        if 'properties' in self.input_schema:
            for param_name, param_info in self.input_schema['properties'].items():
                arg_desc = f"- {param_name}: {param_info.get('description', 'No description')}"
                if param_name in self.input_schema.get('required', []):
                    arg_desc += " (required)"
                args_desc.append(arg_desc)
        
        return f"""
Tool: {self.name}
Description: {self.description}
Arguments:
{chr(10).join(args_desc)}
"""


class LLMClient:
    """Manages communication with the LLM provider."""

    def __init__(self, api_key: str) -> None:
        self.api_key: str = api_key

    def get_response(self, messages: List[Dict[str, str]]) -> str:
        """Get a response from the LLM.
        
        Args:
            messages: A list of message dictionaries.
            
        Returns:
            The LLM's response as a string.
            
        Raises:
            RequestException: If the request to the LLM fails.
        """
        url = "https://api.groq.com/openai/v1/chat/completions"
        # url = "https://models.inference.ai.azure.com/chat/completions"

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }
        payload = {
            "messages": messages,
            "model": "deepseek-r1-distill-llama-70b",
            "temperature": 0.1,
            "max_tokens": 4096,
            "top_p": 1,
            "stream": False,
            "stop": None
        }
        # payload = {
        #     "messages": messages,
        #     "temperature": 1.0,
        #     "top_p": 1.0,
        #     "max_tokens": 4000,
        #     "model": "gpt-4o-mini"
        # }
        
        try:
            response = requests.post(url, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            return data['choices'][0]['message']['content']
            
        except requests.exceptions.RequestException as e:
            error_message = f"Error getting LLM response: {str(e)}"
            logging.error(error_message)
            
            if e.response is not None:
                status_code = e.response.status_code
                logging.error(f"Status code: {status_code}")
                logging.error(f"Response details: {e.response.text}")
                
            return f"I encountered an error: {error_message}. Please try again or rephrase your request."


class ChatSession:
    """Orchestrates the interaction between user, LLM, and tools."""

    def __init__(self, servers: List[Server], llm_client: LLMClient) -> None:
        self.servers: List[Server] = servers
        self.llm_client: LLMClient = llm_client

    async def cleanup_servers(self) -> None:
        """Clean up all servers properly."""
        cleanup_tasks = []
        for server in self.servers:
            cleanup_tasks.append(asyncio.create_task(server.cleanup()))
        
        if cleanup_tasks:
            try:
                await asyncio.gather(*cleanup_tasks, return_exceptions=True)
            except Exception as e:
                logging.warning(f"Warning during final cleanup: {e}")

    async def process_llm_response(self, llm_response: str) -> str:
        """Process the LLM response and execute tools if needed.
        
        Args:
            llm_response: The response from the LLM.
            
        Returns:
            The result of tool execution or the original response.
        """
        import json
        try:
            tool_call = json.loads(llm_response)
            if "tool" in tool_call and "arguments" in tool_call:
                logging.info(f"Executing tool: {tool_call['tool']}")
                logging.info(f"With arguments: {tool_call['arguments']}")
                
                for server in self.servers:
                    tools = await server.list_tools()
                    if any(tool.name == tool_call["tool"] for tool in tools):
                        try:
                            result = await server.execute_tool(tool_call["tool"], tool_call["arguments"])
                            
                            if isinstance(result, dict) and 'progress' in result:
                                progress = result['progress']
                                total = result['total']
                                logging.info(f"Progress: {progress}/{total} ({(progress/total)*100:.1f}%)")
                                
                            return f"Tool execution result: {result}"
                        except Exception as e:
                            error_msg = f"Error executing tool: {str(e)}"
                            logging.error(error_msg)
                            return error_msg
                
                return f"No server found with tool: {tool_call['tool']}"
            return llm_response
        except json.JSONDecodeError:
            return llm_response

    async def start(self) -> None:
        """Main chat session handler."""
        try:
            for server in self.servers:
                try:
                    await server.initialize()
                except Exception as e:
                    logging.error(f"Failed to initialize server: {e}")
                    await self.cleanup_servers()
                    return
            
            all_tools = []
            for server in self.servers:
                tools = await server.list_tools()
                all_tools.extend(tools)
            
            tools_description = "\n".join([tool.format_for_llm() for tool in all_tools])
            
            system_message = f"""
Eres un amigable experto SQL con acceso a un esquema de base de datos.
Tienes acceso a las siguientes tablas y herramientas:   
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

            messages = [
                {
                    "role": "system",
                    "content": system_message
                }
            ]

            while True:
                try:
                    user_input = input("You: ").strip().lower()
                    if user_input in ['quit', 'exit']:
                        logging.info("\nExiting...")
                        break

                    messages.append({"role": "user", "content": user_input})
                    
                    llm_response = self.llm_client.get_response(messages)
                    logging.info("\nAssistant: %s", llm_response)
                    match = re.search(r'\{\s*"tool"\s*:\s*".+?",\s*"arguments"\s*:\s*\{.*?\}\s*\}', llm_response, re.DOTALL)
                    if match:
                        json_str = match.group(0)
                        llm_response = json_str
                    result = await self.process_llm_response(llm_response)
                    
                    if result != llm_response:
                        messages.append({"role": "assistant", "content": llm_response})
                        messages.append({"role": "system", "content": result})
                        
                        final_response = self.llm_client.get_response(messages)
                        logging.info("\nFinal response: %s", final_response)
                        messages.append({"role": "assistant", "content": final_response})
                    else:
                        messages.append({"role": "assistant", "content": llm_response})

                except KeyboardInterrupt:
                    logging.info("\nExiting...")
                    break
        
        finally:
            await self.cleanup_servers()


async def main() -> None:
    """Initialize and run the chat session."""
    config = Configuration()
    server_config = config.load_config('servers_config.json')
    servers = [Server(name, srv_config) for name, srv_config in server_config['mcpServers'].items()]
    llm_client = LLMClient(config.llm_api_key)
    chat_session = ChatSession(servers, llm_client)
    await chat_session.start()

if __name__ == "__main__":
    asyncio.run(main())