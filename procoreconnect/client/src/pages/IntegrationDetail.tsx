import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import {
  deleteIntegration,
  getIntegration,
  listSyncLogs,
  listWebhookEvents,
  updateIntegration,
} from "../api/client";
import type { Integration, IntegrationStatus, SyncLog, WebhookEvent } from "../types";
import { StatusBadge } from "../components/StatusBadge";
import { SyncLogTable } from "../components/SyncLogTable";
import { WebhookEventList } from "../components/WebhookEventList";
import { SyncChart } from "../components/SyncChart";
import { WebhookSetup } from "../components/WebhookSetup";
import { ErrorState, LoadingState } from "../components/LoadingState";
import { formatDateTime } from "../utils/format";

const STATUS_CHOICES: IntegrationStatus[] = ["active", "paused", "error"];

export function IntegrationDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const integrationId = Number(id);

  const [integration, setIntegration] = useState<Integration | null>(null);
  const [logs, setLogs] = useState<SyncLog[]>([]);
  const [events, setEvents] = useState<WebhookEvent[]>([]);
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [errorMessage, setErrorMessage] = useState<string>("");
  const [updating, setUpdating] = useState(false);

  const load = useCallback(async () => {
    if (!Number.isFinite(integrationId)) {
      setStatus("error");
      setErrorMessage("Invalid integration id.");
      return;
    }
    setStatus("loading");
    try {
      const [i, l, e] = await Promise.all([
        getIntegration(integrationId),
        listSyncLogs(integrationId),
        listWebhookEvents(integrationId),
      ]);
      setIntegration(i);
      setLogs(l);
      setEvents(e);
      setStatus("success");
    } catch (err) {
      setStatus("error");
      setErrorMessage(err instanceof Error ? err.message : "Failed to load integration.");
    }
  }, [integrationId]);

  useEffect(() => {
    load();
  }, [load]);

  async function handleStatusChange(next: IntegrationStatus) {
    if (!integration) return;
    setUpdating(true);
    try {
      const updated = await updateIntegration(integration.id, { status: next });
      setIntegration(updated);
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : "Update failed.");
    } finally {
      setUpdating(false);
    }
  }

  async function handleDelete() {
    if (!integration) return;
    if (!confirm(`Delete integration "${integration.name}"? This cannot be undone.`)) return;
    try {
      await deleteIntegration(integration.id);
      navigate("/");
    } catch (err) {
      setErrorMessage(err instanceof Error ? err.message : "Delete failed.");
    }
  }

  if (status === "loading") return <LoadingState label="Loading integration..." />;
  if (status === "error") return <ErrorState message={errorMessage} onRetry={load} />;
  if (!integration) return null;

  return (
    <div className="space-y-8">
      <div>
        <Link
          to="/"
          className="text-sm font-medium text-ink-500 transition hover:text-brand-600"
        >
          ← Back to dashboard
        </Link>
      </div>

      <section className="rounded-2xl border border-ink-100 bg-white p-6 shadow-card">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="min-w-0">
            <div className="flex flex-wrap items-center gap-3">
              <h1 className="text-3xl font-bold tracking-tight text-ink-900">
                {integration.name}
              </h1>
              <StatusBadge status={integration.status} />
            </div>
            <p className="mt-2 break-all font-mono text-sm text-ink-500">
              {integration.api_endpoint}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <select
              value={integration.status}
              disabled={updating}
              onChange={(e) => handleStatusChange(e.target.value as IntegrationStatus)}
              className="rounded-md border border-ink-200 bg-white px-3 py-2 text-sm font-medium text-ink-700 shadow-sm transition focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
            >
              {STATUS_CHOICES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
            <button
              type="button"
              onClick={handleDelete}
              className="rounded-md border border-ink-200 bg-white px-3 py-2 text-sm font-medium text-ink-700 shadow-sm transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700"
            >
              Delete
            </button>
          </div>
        </div>

        <dl className="mt-6 grid grid-cols-2 gap-x-6 gap-y-4 border-t border-ink-100 pt-6 md:grid-cols-4">
          <Stat label="Sync logs" value={integration.sync_logs_count} />
          <Stat label="Pending events" value={integration.pending_webhook_events_count} />
          <Stat label="Last synced" value={formatDateTime(integration.last_synced_at)} />
          <Stat label="Webhook URL" value={integration.webhook_url ?? "—"} mono />
        </dl>
      </section>

      <WebhookSetup integration={integration} />

      <SyncChart logs={logs} />

      <section>
        <h2 className="mb-3 text-xl font-bold tracking-tight text-ink-900">Sync logs</h2>
        <SyncLogTable logs={logs} />
      </section>

      <section>
        <h2 className="mb-3 text-xl font-bold tracking-tight text-ink-900">Webhook events</h2>
        <WebhookEventList events={events} />
      </section>
    </div>
  );
}

interface StatProps {
  label: string;
  value: string | number;
  mono?: boolean;
}

function Stat({ label, value, mono }: StatProps) {
  return (
    <div className="min-w-0">
      <dt className="text-[10px] font-semibold uppercase tracking-wider text-ink-400">
        {label}
      </dt>
      <dd
        className={`mt-1 truncate font-semibold text-ink-900 ${mono ? "font-mono text-sm" : ""}`}
        title={String(value)}
      >
        {value}
      </dd>
    </div>
  );
}
