import { Link } from "react-router-dom";
import type { Integration } from "../types";
import { StatusBadge } from "./StatusBadge";
import { formatRelativeTime } from "../utils/format";

interface IntegrationCardProps {
  integration: Integration;
}

export function IntegrationCard({ integration }: IntegrationCardProps) {
  return (
    <Link
      to={`/integrations/${integration.id}`}
      className="group block rounded-xl border border-ink-100 bg-white p-5 shadow-card transition hover:-translate-y-0.5 hover:border-brand-300 hover:shadow-md"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h3 className="truncate text-lg font-semibold text-ink-900 group-hover:text-brand-700">
            {integration.name}
          </h3>
          <p className="mt-1 truncate font-mono text-xs text-ink-500">
            {integration.api_endpoint}
          </p>
        </div>
        <StatusBadge status={integration.status} />
      </div>

      <dl className="mt-5 grid grid-cols-3 gap-3 border-t border-ink-100 pt-4 text-sm">
        <div>
          <dt className="text-[10px] font-semibold uppercase tracking-wider text-ink-400">
            Sync logs
          </dt>
          <dd className="mt-0.5 font-semibold text-ink-900">{integration.sync_logs_count}</dd>
        </div>
        <div>
          <dt className="text-[10px] font-semibold uppercase tracking-wider text-ink-400">
            Pending
          </dt>
          <dd className="mt-0.5 font-semibold text-ink-900">
            {integration.pending_webhook_events_count}
          </dd>
        </div>
        <div>
          <dt className="text-[10px] font-semibold uppercase tracking-wider text-ink-400">
            Last sync
          </dt>
          <dd className="mt-0.5 font-semibold text-ink-900">
            {formatRelativeTime(integration.last_synced_at) ?? "never"}
          </dd>
        </div>
      </dl>
    </Link>
  );
}
