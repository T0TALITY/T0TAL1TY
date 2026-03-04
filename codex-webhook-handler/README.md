# Codex Webhook Handler

Production-ready webhook receiver for Codex events with:

- fast 2xx ACK responses,
- optional HMAC signature validation,
- deduplication support,
- Docker + PM2 runtime options.

## Quick start

```bash
cd codex-webhook-handler
cp .env.example .env
npm install
npm run start
```

### Test locally

```bash
curl -X POST http://localhost:5000/codex-webhook \
  -H "Content-Type: application/json" \
  -d '{"event":"content.save","webhookId":"abc-123","deduplicationId":"abc-123","data":{"id":123}}'
```

## Environment variables

- `PORT`: HTTP port (default `5000`)
- `WEBHOOK_PATH`: endpoint path (default `/codex-webhook`)
- `WEBHOOK_SECRET`: shared secret for HMAC SHA256 (`x-codex-signature: sha256=<hex>`)
- `DEDUP_TTL_MS`: deduplication window in milliseconds

## Docker

```bash
docker build -t codex-webhook-handler .
docker run --rm -p 5000:5000 --env-file .env codex-webhook-handler
```

## PM2

```bash
npm install -g pm2
pm2 start ecosystem.config.cjs
pm2 save
```
