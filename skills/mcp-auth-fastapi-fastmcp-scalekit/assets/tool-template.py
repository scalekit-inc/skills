@mcp.tool(name="<tool_name>", description="<Tool description>")
async def <tool_name>(<param>: <type>, ctx: Context | None = None) -> dict:
    """
    <Description of what this tool does>.
    Requires: <scope> scope.
    """
    # TODO: implement scope check if needed
    # token = ctx.request.state.token
    # if "<scope>" not in token.get("scopes", []):
    #     return {"error": "Insufficient scope: <scope> required"}

    # TODO: implement tool logic here
    return {"content": [{"type": "text", "text": "Result"}]}
