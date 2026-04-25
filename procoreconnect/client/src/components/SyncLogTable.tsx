import type { SyncLog } from "../types";
import { StatusBadge } from "./StatusBadge";
import { formatDateTime } from "../utils/format";

interface SyncLogTableProps {
  logs: SyncLog[];
}

export function SyncLogTable({ logs }: SyncLogTableProps) {
  if (logs.length === 0) {
    return (
      <div className="rounded-xl border border-dashed border-ink-200 bg-white p-10 text-center text-sm text-ink-500 shadow-card">
        No sync activity yet.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-xl border border-ink-100 bg-white shadow-card">
      <table className="min-w-full divide-y divide-ink-100 text-sm">
        <thead className="bg-ink-50 text-left text-[11px] uppercase tracking-wider text-ink-500">
          <tr>
            <th className="px-4 py-3 font-semibold">When</th>
            <th className="px-4 py-3 font-semibold">Event</th>
            <th className="px-4 py-3 font-semibold">Status</th>
            <th className="px-4 py-3 font-semibold">HTTP</th>
            <th className="px-4 py-3 font-semibold">Error</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-ink-100">
          {logs.map((log) => (
            <tr key={log.id} className="transition hover:bg-brand-50/40">
              <td className="whitespace-nowrap px-4 py-3 text-ink-700">
                {formatDateTime(log.created_at)}
              </td>
              <td className="px-4 py-3 font-mono text-xs text-ink-700">{log.event_type}</td>
              <td className="px-4 py-3">
                <StatusBadge status={log.status} />
              </td>
              <td className="px-4 py-3 font-mono text-ink-700">{log.response_code ?? "—"}</td>
              <td className="max-w-xs px-4 py-3 text-ink-500">
                <span className="block truncate" title={log.error_message ?? ""}>
                  {log.error_message ?? "—"}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
