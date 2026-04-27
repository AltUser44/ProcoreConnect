import { FormEvent, useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import axios from "axios";
import { useAuth } from "../contexts/AuthContext";
import { AuthShell } from "./Login";
import { PasswordRevealInput } from "../components/PasswordRevealInput";

export function Register() {
  const { status, register } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);

  if (status === "authenticated") return <Navigate to="/" replace />;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setErrors([]);

    if (password !== confirmation) {
      setErrors(["Password confirmation doesn't match."]);
      return;
    }
    if (password.length < 8) {
      setErrors(["Password must be at least 8 characters."]);
      return;
    }

    setSubmitting(true);
    try {
      await register({
        email: email.trim(),
        password,
        password_confirmation: confirmation,
      });
      navigate("/", { replace: true });
    } catch (err) {
      if (axios.isAxiosError(err)) {
        const data = err.response?.data as { errors?: string[]; error?: string } | undefined;
        if (Array.isArray(data?.errors)) setErrors(data.errors);
        else if (data?.error) setErrors([data.error]);
        else setErrors(["Registration failed."]);
      } else {
        setErrors([err instanceof Error ? err.message : "Registration failed."]);
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      title="Create your account"
      subtitle="Connect your first integration in minutes."
    >
      {errors.length > 0 && (
        <div className="rounded-lg border border-brand-200 bg-brand-50 px-3 py-2 text-sm text-brand-800">
          <ul className="list-inside list-disc">
            {errors.map((msg) => (
              <li key={msg}>{msg}</li>
            ))}
          </ul>
        </div>
      )}
      <form onSubmit={handleSubmit} className="space-y-4">
        <Field label="Email" htmlFor="email">
          <input
            id="email"
            type="email"
            required
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className={inputClass}
          />
        </Field>
        <Field label="Password" htmlFor="password" hint="Minimum 8 characters.">
          <PasswordRevealInput
            id="password"
            required
            minLength={8}
            autoComplete="new-password"
            value={password}
            onChange={setPassword}
          />
        </Field>
        <Field label="Confirm password" htmlFor="confirmation">
          <PasswordRevealInput
            id="confirmation"
            required
            minLength={8}
            autoComplete="new-password"
            value={confirmation}
            onChange={setConfirmation}
          />
        </Field>
        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-md bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {submitting ? "Creating account..." : "Create account"}
        </button>
      </form>
      <p className="text-center text-sm text-ink-500">
        Already have an account?{" "}
        <Link to="/login" className="font-semibold text-brand-600 hover:underline">
          Sign in
        </Link>
      </p>
    </AuthShell>
  );
}

const inputClass =
  "block w-full rounded-md border border-ink-200 bg-white px-3 py-2 text-sm text-ink-900 shadow-sm transition placeholder:text-ink-400 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500";

interface FieldProps {
  label: string;
  htmlFor: string;
  hint?: string;
  children: React.ReactNode;
}

function Field({ label, htmlFor, hint, children }: FieldProps) {
  return (
    <div>
      <label
        htmlFor={htmlFor}
        className="mb-1.5 block text-sm font-semibold text-ink-700"
      >
        {label}
      </label>
      {children}
      {hint && <p className="mt-1.5 text-xs text-ink-500">{hint}</p>}
    </div>
  );
}
