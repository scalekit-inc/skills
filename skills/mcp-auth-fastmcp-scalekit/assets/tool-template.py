@mcp.tool
def <tool_name>(<param>: <type>) -> dict:
    """
    <Description of what this tool does>.
    Requires: <scope> scope.
    """
    error = _require_scope("<scope>")
    if error:
        return {"error": error}

    # TODO: implement tool logic here
    return {"result": None}
