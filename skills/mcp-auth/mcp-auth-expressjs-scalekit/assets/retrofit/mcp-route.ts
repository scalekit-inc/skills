import { Request, Response } from 'express';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';

export function createMcpRoute(server: McpServer) {
  return async (req: Request, res: Response) => {
    const transport = new StreamableHTTPServerTransport('/message', {
      SSEWriter: (data) => {
        res.write(`data: ${data}\n\n`);
      }
    });

    await server.connect(transport);

    req.on('data', async (chunk) => {
      await transport.handlePostMessage(chunk.toString(), req);
    });
  };
}
