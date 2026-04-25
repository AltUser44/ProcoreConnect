import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { SyncLog } from "../types";

interface SyncChartProps {
  logs: SyncLog[];
  days?: number;
}

interface DayBucket {
  date: string;
  success: number;
  failed: number;
  pending: number;
}

function buildBuckets(logs: SyncLog[], days: number): DayBucket[] {
  const buckets = new Map<string, DayBucket>();

  const now = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    buckets.set(key, { date: key.slice(5), success: 0, failed: 0, pending: 0 });
  }

  for (const log of logs) {
    const key = log.created_at.slice(0, 10);
    const bucket = buckets.get(key);
    if (!bucket) continue;
    if (log.status === "success") bucket.success += 1;
    else if (log.status === "failed") bucket.failed += 1;
    else bucket.pending += 1;
  }

  return Array.from(buckets.values());
}

export function SyncChart({ logs, days = 14 }: SyncChartProps) {
  const data = buildBuckets(logs, days);

  return (
    <div className="rounded-xl border border-ink-100 bg-white p-5 shadow-card">
      <div className="mb-4 flex items-baseline justify-between">
        <h3 className="text-sm font-semibold text-ink-900">Sync activity</h3>
        <span className="text-xs text-ink-400">last {days} days</span>
      </div>
      <ResponsiveContainer width="100%" height={240}>
        <BarChart data={data} margin={{ top: 8, right: 16, left: -8, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#eceef2" />
          <XAxis dataKey="date" stroke="#7c8497" fontSize={11} />
          <YAxis stroke="#7c8497" fontSize={11} allowDecimals={false} />
          <Tooltip
            contentStyle={{
              borderRadius: 8,
              border: "1px solid #d4d8e0",
              fontSize: 12,
            }}
          />
          <Legend wrapperStyle={{ fontSize: 12 }} />
          <Bar dataKey="success" stackId="a" fill="#10b981" name="success" radius={[0, 0, 0, 0]} />
          <Bar dataKey="failed" stackId="a" fill="#f24f00" name="failed" />
          <Bar dataKey="pending" stackId="a" fill="#aab0bc" name="pending" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
