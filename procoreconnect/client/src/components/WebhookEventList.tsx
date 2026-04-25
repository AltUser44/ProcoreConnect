import type { WebhookEvent } from "../types";
import { StatusBadge } from "./StatusBadge";
import { formatDateTime } from "../utils/format";

interface WebhookEventListProps {
  events: WebhookEvent[];
}

export function WebhookEventList({ events }: WebhookEventListProps) {
  if (events.length === 0) {
    return (
      <div className="rounded-xl border border-dashed border-ink-200 bg-white p-10 text-center text-sm text-ink-500 shadow-card">
        No webhook events received yet.
      </div>
    );
  }

  return (
    <ul className="space-y-2">
      {events.map((event) => (
        <li
          key={event.id}
          className="flex items-start justify-between gap-3 rounded-xl border border-ink-100 bg-white p-4 shadow-card"
        >
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs text-ink-700">{event.event_type}</span>
              <StatusBadge status={event.processed ? "processed" : "unprocessed"} />
            </div>
            <p className="mt-1 text-xs text-ink-500">
              Received {formatDateTime(event.created_at)}
              {event.processed_at && ` · Processed ${formatDateTime(event.processed_at)}`}
            </p>
            <details className="mt-2">
              <summary className="cursor-pointer text-xs font-semibold text-brand-600 hover:text-brand-700">
                View payload
              </summary>
              <pre className="mt-2 max-h-48 overflow-auto rounded-lg bg-ink-900 p-3 text-xs text-ink-100">
                {JSON.stringify(event.payload, null, 2)}
              </pre>
            </details>
          </div>
        </li>
      ))}
    </ul>
  );
}
