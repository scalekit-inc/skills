import { Request, Response, NextFunction } from 'express';
import { Scalekit } from '@scalekit-sdk/node';

const scalekit = new Scalekit(
  process.env.SK_ENV_URL!,
  process.env.SK_CLIENT_ID!,
  process.env.SK_CLIENT_SECRET!
);

const EXPECTED_AUDIENCE = process.env.EXPECTED_AUDIENCE!;
const METADATA_URL = `${EXPECTED_AUDIENCE}.well-known/oauth-protected-resource`;

export async function authMiddleware(req: Request, res: Response, next: NextFunction) {
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
}

export const WWW_AUTHENTICATE_HEADER = `Bearer realm="OAuth", resource_metadata="${METADATA_URL}"`;
