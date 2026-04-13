import os
from dotenv import load_dotenv
from fastmcp import FastMCP
from fastmcp.server.auth.providers.scalekit import ScalekitProvider
from fastmcp.server.dependencies import AccessToken, get_access_token

load_dotenv()

mcp = FastMCP(
    "Todo MCP Server",
    stateless_http=True,
    auth=ScalekitProvider(
        environment_url=os.getenv("SCALEKIT_ENVIRONMENT_URL"),
        client_id=os.getenv("SCALEKIT_CLIENT_ID"),
        resource_id=os.getenv("SCALEKIT_RESOURCE_ID"),
        mcp_url=os.getenv("MCP_URL"),
    ),
)

todos = {}


def _require_scope(scope: str):
    token: AccessToken = get_access_token()
    if scope not in token.scopes:
        return f"Insufficient permissions: `{scope}` scope required."
    return None


@mcp.tool
def list_todos() -> dict:
    """List all todos. Requires: todo:read scope."""
    error = _require_scope("todo:read")
    if error:
        return {"error": error}
    return {"todos": list(todos.values())}


@mcp.tool
def create_todo(text: str) -> dict:
    """Create a new todo. Requires: todo:write scope."""
    error = _require_scope("todo:write")
    if error:
        return {"error": error}
    todo_id = str(len(todos) + 1)
    todos[todo_id] = {"id": todo_id, "text": text, "done": False}
    return {"todo": todos[todo_id]}


@mcp.tool
def update_todo(todo_id: str, text: str = None, done: bool = None) -> dict:
    """Update an existing todo. Requires: todo:write scope."""
    error = _require_scope("todo:write")
    if error:
        return {"error": error}
    if todo_id not in todos:
        return {"error": "Todo not found"}
    if text is not None:
        todos[todo_id]["text"] = text
    if done is not None:
        todos[todo_id]["done"] = done
    return {"todo": todos[todo_id]}


@mcp.tool
def delete_todo(todo_id: str) -> dict:
    """Delete a todo. Requires: todo:write scope."""
    error = _require_scope("todo:write")
    if error:
        return {"error": error}
    if todo_id not in todos:
        return {"error": "Todo not found"}
    deleted = todos.pop(todo_id)
    return {"deleted": deleted}


if __name__ == "__main__":
    mcp.run(transport="http", port=int(os.getenv("PORT", "3002")))
