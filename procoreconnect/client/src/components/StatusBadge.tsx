import type { IntegrationStatus, SyncLogStatus } from "../types";

type Variant = IntegrationStatus | SyncLogStatus | "processed" | "unprocessed";

interface StatusBadgeProps {
  status: Variant;
}

const STYLES: Record<Variant, string> = {
  active: "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
  paused: "bg-amber-50 text-amber-700 ring-amber-600/20",
  error: "bg-brand-50 text-brand-700 ring-brand-600/30",
  failed: "bg-brand-50 text-brand-700 ring-brand-600/30",
  success: "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
  pending: "bg-ink-100 text-ink-600 ring-ink-300/40",
  processed: "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
  unprocessed: "bg-amber-50 text-amber-700 ring-amber-600/20",
};

export function StatusBadge({ status }: StatusBadgeProps) {
  const style = STYLES[status] ?? STYLES.pending;

  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-[11px] font-semibold uppercase tracking-wide ring-1 ring-inset ${style}`}
    >
      {status}
    </span>
  );
}
