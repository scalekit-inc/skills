# Integrate AgentKit — Node

Same default path as `SKILL.md`: **connection** → **connected account** → authorization link if not `ACTIVE` → fetch token → one downstream API call.

Use this file when the repo is Node. Do not run the Python samples in `SKILL.md`.

Env names: `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, `SCALEKIT_CLIENT_SECRET`. Some samples use `SCALEKIT_ENV_URL`; use `SCALEKIT_ENVIRONMENT_URL` here.

Field name is `connectionName`. Never pass a `connector` field.

## Step 2 — Init the SDK

If env vars are missing, collect them from [app.scalekit.com](https://app.scalekit.com) → Developers → Settings → API Credentials. Put them in the project env file. Do not invent values.

```bash
npm install @scalekit-sdk/node
```

```typescript
import { ScalekitClient } from '@scalekit-sdk/node';
import 'dotenv/config';

const scalekitClient = new ScalekitClient(
  process.env.SCALEKIT_ENVIRONMENT_URL!,
  process.env.SCALEKIT_CLIENT_ID!,
  process.env.SCALEKIT_CLIENT_SECRET!
);
const { actions } = scalekitClient;
```

**Done when:** the client initializes from those three env vars, and source files do not hardcode the secret.

## Step 3 — Create the connected account

Replace `"user_123"` with the project's user id. Replace `"gmail"` with the recorded Connection Name.

```typescript
const response = await actions.getOrCreateConnectedAccount({
  connectionName: 'gmail',
  identifier: 'user_123',
});
const connectedAccount = response.connectedAccount;
```

**Done when:** a connected account exists for that identifier and Connection Name.

## Step 4 — Authorization link if not ACTIVE

If `connectedAccount?.status` is `ACTIVE`, skip this step.

Put the `readline` import at the top of the file.

```typescript
import * as readline from 'node:readline/promises';

if (connectedAccount?.status !== 'ACTIVE') {
  const linkResponse = await actions.getAuthorizationLink({
    connectionName: 'gmail',
    identifier: 'user_123',
  });
  console.log('Authorize here:', linkResponse.link);
  if (!process.stdin.isTTY) {
    console.log('Complete OAuth in a browser, then re-run from Step 5 (fetch tokens).');
    process.exit(0);
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  await rl.question('Press Enter after authorizing…');
  rl.close();
}
```

In a web app, redirect the browser to `linkResponse.link`.

**Done when:** status is `ACTIVE`, or the authorization link is printed. A non-interactive run stops here until the user finishes OAuth.

## Step 5 — Fetch the token

Re-fetch immediately. Do not reuse a token from Step 3.

```typescript
const accountResponse = await actions.getConnectedAccount({
  connectionName: 'gmail',
  identifier: 'user_123',
});
// authorizationDetails is a oneof: when case is 'oauthToken', value holds the tokens
const authDetails = accountResponse?.connectedAccount?.authorizationDetails;
const oauth = authDetails?.details?.case === 'oauthToken'
  ? authDetails.details.value
  : undefined;
const accessToken = oauth?.accessToken;
const refreshToken = oauth?.refreshToken;
```

**Done when:** `accessToken` is present.

## Step 6 — Call one downstream API

Use `accessToken` as a Bearer token. Default: five unread Gmail messages.

```typescript
const listUrl = 'https://gmail.googleapis.com/gmail/v1/users/me/messages';
const params = new URLSearchParams({ q: 'is:unread', maxResults: '5' });

const { messages = [] } = await fetch(`${listUrl}?${params}`, {
  headers: { Authorization: `Bearer ${accessToken}` },
}).then(r => r.json());

for (const msg of messages) {
  const msgData = await fetch(
    `${listUrl}/${msg.id}?format=metadata&metadataHeaders=From&metadataHeaders=Subject&metadataHeaders=Date`,
    { headers: { Authorization: `Bearer ${accessToken}` } }
  ).then(r => r.json());

  const h = msgData.payload?.headers ?? [];
  console.log('Subject:', h.find(x => x.name === 'Subject')?.value ?? 'No Subject');
  console.log('From:', h.find(x => x.name === 'From')?.value ?? 'Unknown');
  console.log('Snippet:', msgData.snippet ?? '');
  console.log('-'.repeat(50));
}
```

For a non-Gmail connector, keep the same token path. Change only this HTTP call. Look up the provider API from https://docs.scalekit.com/agentkit/connectors.md.

**Done when:** one downstream API call succeeds with the fetched token.
