import { useMemo, useState } from "react";
import type { Integration } from "../types";

interface WebhookSetupProps {
  integration: Integration;
}

export function WebhookSetup({ integration }: WebhookSetupProps) {
  const [secretRevealed, setSecretRevealed] = useState(false);
  const apiBase =
    (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? window.location.origin.replace(":3001", ":3000");

  const webhookUrl = useMemo(
    () => `${apiBase}/api/v1/webhooks/${integration.id}`,
    [apiBase, integration.id],
  );

  const sampleCurl = useMemo(
    () =>
      [
        `BODY='{"order_id":12345,"amount":99.99}'`,
        `SIG=$(printf %s "$BODY" | openssl dgst -sha256 -hmac "${integration.webhook_secret}" | sed 's/^.* //')`,
        `curl -X POST ${webhookUrl} \\`,
        `  -H "Content-Type: application/json" \\`,
        `  -H "X-Event-Type: order.created" \\`,
        `  -H "X-Webhook-Signature: sha256=$SIG" \\`,
        `  -d "$BODY"`,
      ].join("\n"),
    [webhookUrl, integration.webhook_secret],
  );

  const masked = `${integration.webhook_secret.slice(0, 6)}${"•".repeat(52)}${integration.webhook_secret.slice(-6)}`;

  return (
    <section className="rounded-2xl border border-ink-100 bg-white p-6 shadow-card">
      <div className="mb-4 flex items-start justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-ink-900">Webhook setup</h2>
          <p className="mt-1 text-sm text-ink-500">
            Point your third-party system at this URL and sign every request with the
            secret below using <span className="font-mono">HMAC-SHA256</span>.
            Unsigned or tampered requests are rejected with 401.
          </p>
        </div>
      </div>

      <div className="space-y-4">
        <Field label="Webhook URL">
          <CopyableCode value={webhookUrl} />
        </Field>

        <Field label="Webhook secret" hint="Treat this like a password — never commit it.">
          <div className="flex items-center gap-2">
            <CopyableCode value={secretRevealed ? integration.webhook_secret : masked} />
            <button
              type="button"
              onClick={() => setSecretRevealed((v) => !v)}
              className="shrink-0 rounded-md border border-ink-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700 shadow-sm transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700"
            >
              {secretRevealed ? "Hide" : "Reveal"}
            </button>
          </div>
        </Field>

        <Field label="Required headers">
          <ul className="space-y-1 text-sm text-ink-600">
            <li>
              <span className="font-mono text-xs text-ink-900">Content-Type:</span>{" "}
              <span className="font-mono text-xs">application/json</span>
            </li>
            <li>
              <span className="font-mono text-xs text-ink-900">X-Event-Type:</span>{" "}
              <span className="font-mono text-xs">your.event.name</span>{" "}
              <span className="text-xs text-ink-400">(optional)</span>
            </li>
            <li>
              <span className="font-mono text-xs text-ink-900">X-Webhook-Signature:</span>{" "}
              <span className="font-mono text-xs">sha256={"<hex digest>"}</span>
            </li>
          </ul>
        </Field>

        <Field label="Example (bash + openssl)">
          <CopyableBlock value={sampleCurl} />
        </Field>
      </div>
    </section>
  );
}

interface FieldProps {
  label: string;
  hint?: string;
  children: React.ReactNode;
}

function Field({ label, hint, children }: FieldProps) {
  return (
    <div>
      <div className="mb-1.5 flex items-baseline justify-between">
        <span className="text-[10px] font-semibold uppercase tracking-wider text-ink-400">
          {label}
        </span>
        {hint && <span className="text-xs text-ink-400">{hint}</span>}
      </div>
      {children}
    </div>
  );
}

interface CopyableProps {
  value: string;
}

function CopyableCode({ value }: CopyableProps) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Clipboard API unavailable (insecure context) — silently noop.
    }
  }

  return (
    <div className="flex items-center gap-2">
      <code className="flex-1 truncate rounded-md border border-ink-100 bg-ink-50/60 px-3 py-2 font-mono text-xs text-ink-800">
        {value}
      </code>
      <button
        type="button"
        onClick={handleCopy}
        className="shrink-0 rounded-md border border-ink-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700 shadow-sm transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700"
      >
        {copied ? "Copied" : "Copy"}
      </button>
    </div>
  );
}

function CopyableBlock({ value }: CopyableProps) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // ignore
    }
  }

  return (
    <div className="relative">
      <pre className="overflow-x-auto rounded-md border border-ink-100 bg-ink-900 p-3 font-mono text-[11px] leading-relaxed text-ink-100">
        {value}
      </pre>
      <button
        type="button"
        onClick={handleCopy}
        className="absolute right-2 top-2 rounded-md bg-white/90 px-2 py-1 text-xs font-semibold text-ink-700 shadow transition hover:bg-white"
      >
        {copied ? "Copied" : "Copy"}
      </button>
    </div>
  );
}
