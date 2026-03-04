import crypto from "node:crypto";
import express from "express";

const app = express();

const PORT = Number(process.env.PORT || 5000);
const WEBHOOK_PATH = process.env.WEBHOOK_PATH || "/codex-webhook";
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET || "";
const DEDUP_TTL_MS = Number(process.env.DEDUP_TTL_MS || 86_400_000);

const dedupCache = new Map();

function cleanupDedupCache() {
  const now = Date.now();
  for (const [key, value] of dedupCache.entries()) {
    if (value.expiresAt <= now) {
      dedupCache.delete(key);
    }
  }
}

setInterval(cleanupDedupCache, 60_000).unref();

function isDuplicate(deduplicationId) {
  if (!deduplicationId) return false;
  const now = Date.now();
  const existing = dedupCache.get(deduplicationId);
  if (existing && existing.expiresAt > now) return true;
  dedupCache.set(deduplicationId, { expiresAt: now + DEDUP_TTL_MS });
  return false;
}

function verifySignature(rawBody, signatureHeader) {
  if (!WEBHOOK_SECRET) return true;
  if (!signatureHeader) return false;

  const expected = crypto
    .createHmac("sha256", WEBHOOK_SECRET)
    .update(rawBody)
    .digest("hex");

  const provided = signatureHeader.replace(/^sha256=/, "");
  if (provided.length !== expected.length) return false;

  return crypto.timingSafeEqual(Buffer.from(provided), Buffer.from(expected));
}

app.use(express.json({
  verify: (req, _res, buf) => {
    req.rawBody = buf;
  }
}));

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true });
});

app.post(WEBHOOK_PATH, async (req, res) => {
  try {
    const signatureHeader = req.get("x-codex-signature") || "";
    if (!verifySignature(req.rawBody || Buffer.from(""), signatureHeader)) {
      return res.status(401).json({ error: "Invalid signature" });
    }

    const payload = req.body || {};
    const deduplicationId = payload.deduplicationId || payload.webhookId;

    if (isDuplicate(deduplicationId)) {
      return res.status(200).json({ status: "duplicate_ignored" });
    }

    res.status(200).json({ status: "accepted" });

    setImmediate(async () => {
      try {
        console.log("Webhook received", {
          event: payload.event,
          webhookId: payload.webhookId,
          deduplicationId: payload.deduplicationId
        });

        // TODO: enqueue downstream processing (Redis/SQS/Kafka), DB writes, etc.
      } catch (processingError) {
        console.error("Webhook processing failed", processingError);
      }
    });
  } catch (error) {
    console.error("Webhook handler failed", error);
    return res.status(500).json({ error: "internal_error" });
  }

  return undefined;
});

app.listen(PORT, () => {
  console.log(`Codex webhook receiver listening on :${PORT}${WEBHOOK_PATH}`);
});
