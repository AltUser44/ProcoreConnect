import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import axios from "axios";
import { createIntegration } from "../api/client";
import type { IntegrationFormValues } from "../types";

const INITIAL: IntegrationFormValues = {
  name: "",
  api_endpoint: "",
  api_key: "",
  webhook_url: "",
  status: "active",
};

export function NewIntegration() {
  const navigate = useNavigate();
  const [values, setValues] = useState<IntegrationFormValues>(INITIAL);
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);

  function update<K extends keyof IntegrationFormValues>(
    key: K,
    val: IntegrationFormValues[K],
  ) {
    setValues((prev) => ({ ...prev, [key]: val }));
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setErrors([]);
    setSubmitting(true);
    try {
      const payload: IntegrationFormValues = {
        name: values.name.trim(),
        api_endpoint: values.api_endpoint.trim(),
        status: values.status,
      };
      if (values.api_key?.trim()) payload.api_key = values.api_key.trim();
      if (values.webhook_url?.trim()) payload.webhook_url = values.webhook_url.trim();

      const created = await createIntegration(payload);
      navigate(`/integrations/${created.id}`);
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.data) {
        const data = err.response.data as { error?: string; errors?: string[] };
        if (Array.isArray(data.errors)) setErrors(data.errors);
        else if (data.error) setErrors([data.error]);
        else setErrors(["Failed to create integration."]);
      } else {
        setErrors([err instanceof Error ? err.message : "Failed to create integration."]);
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="mx-auto max-w-2xl space-y-8">
      <div>
        <Link
          to="/"
          className="text-sm font-medium text-ink-500 transition hover:text-brand-600"
        >
          ← Back to dashboard
        </Link>
      </div>

      <div>
        <p className="mb-2 text-xs font-semibold uppercase tracking-[0.2em] text-brand-600">
          Connect a new system
        </p>
        <h1 className="text-3xl font-bold tracking-tight text-ink-900">New integration</h1>
        <p className="mt-2 text-sm text-ink-500">
          Connect a third-party REST API to ProcoreConnect. We'll deliver every webhook
          event to its endpoint, with retries and full sync logs.
        </p>
      </div>

      {errors.length > 0 && (
        <div className="rounded-xl border border-brand-200 bg-brand-50 p-4 text-sm text-brand-800 shadow-card">
          <p className="font-semibold">Couldn't save:</p>
          <ul className="mt-1 list-inside list-disc">
            {errors.map((msg) => (
              <li key={msg}>{msg}</li>
            ))}
          </ul>
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        className="space-y-5 rounded-2xl border border-ink-100 bg-white p-6 shadow-card"
      >
        <Field label="Name" htmlFor="name" required>
          <input
            id="name"
            type="text"
            required
            value={values.name}
            onChange={(e) => update("name", e.target.value)}
            placeholder="Acme CRM"
            className={inputClass}
          />
        </Field>

        <Field label="API endpoint" htmlFor="api_endpoint" required>
          <input
            id="api_endpoint"
            type="url"
            required
            value={values.api_endpoint}
            onChange={(e) => update("api_endpoint", e.target.value)}
            placeholder="https://api.example.com/v1/sync"
            className={`${inputClass} font-mono`}
          />
        </Field>

        <Field label="API key" htmlFor="api_key" hint="Sent as Bearer token in outbound calls.">
          <input
            id="api_key"
            type="password"
            value={values.api_key}
            onChange={(e) => update("api_key", e.target.value)}
            placeholder="••••••••"
            className={inputClass}
          />
        </Field>

        <Field
          label="Webhook URL"
          htmlFor="webhook_url"
          hint="Optional reference URL for the third party."
        >
          <input
            id="webhook_url"
            type="url"
            value={values.webhook_url}
            onChange={(e) => update("webhook_url", e.target.value)}
            placeholder="https://example.com/notifications"
            className={inputClass}
          />
        </Field>

        <Field label="Status" htmlFor="status">
          <select
            id="status"
            value={values.status}
            onChange={(e) =>
              update("status", e.target.value as IntegrationFormValues["status"])
            }
            className={inputClass}
          >
            <option value="active">active</option>
            <option value="paused">paused</option>
            <option value="error">error</option>
          </select>
        </Field>

        <div className="flex items-center justify-end gap-2 border-t border-ink-100 pt-5">
          <Link
            to="/"
            className="rounded-md border border-ink-200 bg-white px-4 py-2 text-sm font-medium text-ink-700 hover:bg-ink-50"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={submitting}
            className="rounded-md bg-brand-600 px-5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {submitting ? "Creating..." : "Create integration"}
          </button>
        </div>
      </form>
    </div>
  );
}

const inputClass =
  "block w-full rounded-md border border-ink-200 bg-white px-3 py-2 text-sm text-ink-900 shadow-sm transition placeholder:text-ink-400 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500";

interface FieldProps {
  label: string;
  htmlFor: string;
  required?: boolean;
  hint?: string;
  children: React.ReactNode;
}

function Field({ label, htmlFor, required, hint, children }: FieldProps) {
  return (
    <div>
      <label
        htmlFor={htmlFor}
        className="mb-1.5 block text-sm font-semibold text-ink-700"
      >
        {label}
        {required && <span className="ml-0.5 text-brand-600">*</span>}
      </label>
      {children}
      {hint && <p className="mt-1.5 text-xs text-ink-500">{hint}</p>}
    </div>
  );
}
