import { Request, Response } from 'express';

export function wellKnownRoute(req: Request, res: Response) {
  const metadata = JSON.parse(process.env.PROTECTED_RESOURCE_METADATA!);
  res.json(metadata);
}

export function healthRoute(req: Request, res: Response) {
  res.json({ status: 'healthy' });
}
