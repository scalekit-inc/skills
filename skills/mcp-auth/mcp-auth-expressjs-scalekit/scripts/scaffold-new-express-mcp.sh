#!/bin/bash

set -e

PROJECT_NAME=${1:-express-mcp-server}

echo "Creating new Express MCP server: $PROJECT_NAME"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "Copying package.json..."
cat > package.json << 'EOF'
{
  "name": "express-mcp-auth-server",
  "version": "1.0.0",
  "description": "Express.js MCP server with Scalekit OAuth authentication",
  "main": "dist/server.js",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4",
    "@scalekit-sdk/node": "^2.4.0",
    "cors": "^2.8.5",
    "dotenv": "^16.4.7",
    "express": "^4.21.2"
  },
  "devDependencies": {
    "@types/cors": "^2.8.17",
    "@types/express": "^5.0.0",
    "@types/node": "^22.10.2",
    "tsx": "^4.19.2",
    "typescript": "^5.7.2"
  }
}
EOF

echo "Copying tsconfig.json..."
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022"],
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

echo "Creating .env.example..."
cat > .env.example << 'EOF'
PORT=3002
SK_ENV_URL=https://your-env.scalekit.com
SK_CLIENT_ID=your-client-id
SK_CLIENT_SECRET=your-client-secret
EXPECTED_AUDIENCE=http://localhost:3002/
PROTECTED_RESOURCE_METADATA={"authorization_servers":["https://your-env.scalekit.com/resources/your-resource-id"],"bearer_methods_supported":["header"],"resource":"http://localhost:3002/","resource_documentation":"https://your-docs-url.com","scopes_supported":["todo:read","todo:write"]}
EOF

echo "Copying src/server.ts..."
mkdir -p src
cat > src/server.ts << 'EOF'
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
EOF

echo ""
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. cp .env.example .env"
echo "3. Edit .env with your Scalekit credentials"
echo "4. npm install"
echo "5. npm run dev"
echo ""
echo "After server starts, test with:"
echo "  curl http://localhost:3002/.well-known/oauth-protected-resource"
echo "  npx @modelcontextprotocol/inspector http://localhost:3002/"
