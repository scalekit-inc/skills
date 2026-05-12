import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { Scalekit } from '@scalekit-sdk/node';

const app = express();
const PORT = parseInt(process.env.PORT || '3002', 10);

const scalekit = new Scalekit(
  process.env.SK_ENV_URL!,
  process.env.SK_CLIENT_ID!,
  process.env.SK_CLIENT_SECRET!
);

const EXPECTED_AUDIENCE = process.env.EXPECTED_AUDIENCE!;
const METADATA_URL = `${EXPECTED_AUDIENCE}.well-known/oauth-protected-resource`;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/.well-known/oauth-protected-resource', (req, res) => {
  const metadata = JSON.parse(process.env.PROTECTED_RESOURCE_METADATA!);
  res.json(metadata);
});

const authMiddleware = async (req, res, next) => {
  try {
    if (req.path.startsWith('/.well-known') || req.path === '/health') {
      return next();
    }

    const authHeader = req.headers['authorization'];
    const token = authHeader?.startsWith('Bearer ')
      ? authHeader.split('Bearer ')[1]?.trim()
      : null;

    if (!token) {
      return res
        .status(401)
        .set('WWW-Authenticate', `Bearer realm="OAuth", resource_metadata="${METADATA_URL}"`)
        .end();
    }

    await scalekit.validateToken(token, {
      audience: [EXPECTED_AUDIENCE]
    });

    next();
  } catch (err) {
    return res
      .status(401)
      .set('WWW-Authenticate', `Bearer realm="OAuth", resource_metadata="${METADATA_URL}"`)
      .end();
  }
};

const server = new McpServer(
  { name: 'express-mcp-server', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

server.tool('echo', 'Echo back the input', { message: { type: 'string' } }, async ({ message }) => ({
  content: [{ type: 'text', text: `Echo: ${message}` }]
}));

app.use('/', authMiddleware);

app.all('/', async (req, res) => {
  const transport = new StreamableHTTPServerTransport('/message', {
    SSEWriter: (data) => {
      res.write(`data: ${data}\n\n`);
    }
  });

  await server.connect(transport);

  req.on('data', async (chunk) => {
    await transport.handlePostMessage(chunk.toString(), req);
  });
});

app.listen(PORT, () => {
  console.log(`MCP server running on http://localhost:${PORT}`);
  console.log(`Discovery endpoint: http://localhost:${PORT}/.well-known/oauth-protected-resource`);
});
