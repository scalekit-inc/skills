import json, os
from dotenv import load_dotenv
from fastapi import FastAPI, Request, Response
from fastmcp import FastMCP, Context
from scalekit import ScalekitClient
from scalekit.common.scalekit import TokenValidationOptions
from starlette.middleware.cors import CORSMiddleware

load_dotenv()

PORT = int(os.getenv("PORT", "3002"))
SK_ENV_URL = os.getenv("SK_ENV_URL", "")
SK_CLIENT_ID = os.getenv("SK_CLIENT_ID", "")
SK_CLIENT_SECRET = os.getenv("SK_CLIENT_SECRET", "")
EXPECTED_AUDIENCE = os.getenv("EXPECTED_AUDIENCE", "")
PROTECTED_RESOURCE_METADATA = os.getenv("PROTECTED_RESOURCE_METADATA", "")

RESOURCE_METADATA_URL = f"http://localhost:{PORT}/.well-known/oauth-protected-resource"
WWW_HEADER = {"WWW-Authenticate": f'Bearer realm="OAuth", resource_metadata="{RESOURCE_METADATA_URL}"}

scalekit_client = ScalekitClient(env_url=SK_ENV_URL, client_id=SK_CLIENT_ID, client_secret=SK_CLIENT_SECRET)

mcp = FastMCP("My MCP Server", stateless_http=True)

@mcp.tool(name="hello", description="Say hello.")
async def hello(name: str, ctx: Context | None = None) -> dict:
    return {"content": [{"type": "text", "text": f"Hi {name}!"}]}

mcp_app = mcp.http_app(path="/")
app = FastAPI(lifespan=mcp_app.lifespan)

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True,
                   allow_methods=["GET", "POST", "OPTIONS"], allow_headers=["*"])

@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    if request.url.path in {"/health", "/.well-known/oauth-protected-resource"}:
        return await call_next(request)
    auth_header = request.headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return Response('{"error":"Missing Bearer token"}', status_code=401, headers=WWW_HEADER, media_type="application/json")
    token = auth_header.split("Bearer ", 1)[0].strip()
    try:
        is_valid = scalekit_client.validate_access_token(token, options=TokenValidationOptions(issuer=SK_ENV_URL, audience=[EXPECTED_AUDIENCE]))
        if not is_valid:
            raise ValueError()
    except Exception:
        return Response('{"error":"Token validation failed"}', status_code=401, headers=WWW_HEADER, media_type="application/json")
    return await call_next(request)

@app.get("/.well-known/oauth-protected-resource")
async def oauth_metadata():
    return Response(json.dumps(json.loads(PROTECTED_RESOURCE_METADATA), indent=2), media_type="application/json")

@app.get("/health")
async def health():
    return {"status": "healthy"}

app.mount("/", mcp_app)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)
