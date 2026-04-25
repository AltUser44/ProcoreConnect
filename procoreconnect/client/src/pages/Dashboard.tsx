import { useEffect, useState, useCallback } from "react";
import { Link } from "react-router-dom";
import { listIntegrations } from "../api/client";
import type { Integration } from "../types";
import { IntegrationCard } from "../components/IntegrationCard";
import { ErrorState, LoadingState } from "../components/LoadingState";

export function Dashboard() {
  const [integrations, setIntegrations] = useState<Integration[]>([]);
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("loading");
  const [errorMessage, setErrorMessage] = useState<string>("");

  const load = useCallback(async () => {
    setStatus("loading");
    try {
      const data = await listIntegrations();
      setIntegrations(data);
      setStatus("success");
    } catch (err) {
      setStatus("error");
      setErrorMessage(err instanceof Error ? err.message : "Failed to load integrations.");
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const counts = {
    total: integrations.length,
    active: integrations.filter((i) => i.status === "active").length,
    paused: integrations.filter((i) => i.status === "paused").length,
    errored: integrations.filter((i) => i.status === "error").length,
  };

  return (
    <div className="space-y-8">
      <section className="overflow-hidden rounded-2xl border border-ink-100 bg-gradient-to-br from-white to-brand-50 p-8 shadow-card">
        <div className="flex flex-wrap items-start justify-between gap-6">
          <div className="max-w-2xl">
            <p className="mb-2 text-xs font-semibold uppercase tracking-[0.2em] text-brand-600">
              Together, we connect it all
            </p>
            <h1 className="text-3xl font-bold tracking-tight text-ink-900 sm:text-4xl">
              Integrations
            </h1>
            <p className="mt-3 text-base text-ink-500">
              Bridge your internal systems with third-party APIs in real time. Monitor
              connected systems and review every sync from one dashboard.
            </p>
          </div>
          <Link
            to="/integrations/new"
            className="inline-flex shrink-0 items-center gap-1.5 rounded-md bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-700"
          >
            <span className="text-base leading-none">+</span> New integration
          </Link>
        </div>
      </section>

      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <StatCard label="Total" value={counts.total} accent="text-ink-900" />
        <StatCard label="Active" value={counts.active} accent="text-emerald-600" />
        <StatCard label="Paused" value={counts.paused} accent="text-amber-600" />
        <StatCard label="Errored" value={counts.errored} accent="text-brand-600" />
      </div>

      {status === "loading" && <LoadingState label="Loading integrations..." />}
      {status === "error" && <ErrorState message={errorMessage} onRetry={load} />}

      {status === "success" && integrations.length === 0 && (
        <div className="rounded-2xl border border-dashed border-ink-200 bg-white p-12 text-center shadow-card">
          <div className="mx-auto mb-4 grid h-12 w-12 place-items-center rounded-full bg-brand-50 text-2xl text-brand-600">
            +
          </div>
          <h3 className="text-lg font-semibold text-ink-900">No integrations yet</h3>
          <p className="mt-1 text-sm text-ink-500">
            Connect your first third-party API to start syncing.
          </p>
          <Link
            to="/integrations/new"
            className="mt-5 inline-flex items-center gap-1.5 rounded-md bg-brand-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-brand-700"
          >
            Create integration
          </Link>
        </div>
      )}

      {status === "success" && integrations.length > 0 && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {integrations.map((i) => (
            <IntegrationCard key={i.id} integration={i} />
          ))}
        </div>
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  accent,
}: {
  label: string;
  value: number;
  accent: string;
}) {
  return (
    <div className="rounded-xl border border-ink-100 bg-white p-5 shadow-card">
      <p className="text-[11px] font-semibold uppercase tracking-[0.15em] text-ink-400">
        {label}
      </p>
      <p className={`mt-2 text-3xl font-bold ${accent}`}>{value}</p>
    </div>
  );
}
