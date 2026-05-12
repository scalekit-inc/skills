import os
from dotenv import load_dotenv
from fastmcp import FastMCP
from fastmcp.server.auth.providers.scalekit import ScalekitProvider
from fastmcp.server.dependencies import AccessToken, get_access_token

load_dotenv()

mcp = FastMCP(
    "My MCP Server",
    stateless_http=True,
    auth=ScalekitProvider(
        environment_url=os.getenv("SCALEKIT_ENVIRONMENT_URL"),
        client_id=os.getenv("SCALEKIT_CLIENT_ID"),
        resource_id=os.getenv("SCALEKIT_RESOURCE_ID"),
        mcp_url=os.getenv("MCP_URL"),
    ),
)


def _require_scope(scope: str):
    token: AccessToken = get_access_token()
    if scope not in token.scopes:
        return f"Insufficient permissions: `{scope}` scope required."
    return None


@mcp.tool
def hello(name: str) -> dict:
    """Say hello. Requires: example:read scope."""
    error = _require_scope("example:read")
    if error:
        return {"error": error}
    return {"message": f"Hello, {name}!"}


if __name__ == "__main__":
    mcp.run(transport="http", port=int(os.getenv("PORT", "3002")))
