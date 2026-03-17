import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';

export function createMcpServer() {
  const server = new McpServer(
    { name: 'express-mcp-server', version: '1.0.0' },
    { capabilities: { tools: {} } }
  );

  server.tool('echo', 'Echo back the input', { message: { type: 'string' } }, async ({ message }) => ({
    content: [{ type: 'text', text: `Echo: ${message}` }]
  }));

  return server;
}
