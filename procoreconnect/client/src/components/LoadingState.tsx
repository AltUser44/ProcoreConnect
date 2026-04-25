interface LoadingStateProps {
  label?: string;
}

export function LoadingState({ label = "Loading..." }: LoadingStateProps) {
  return (
    <div className="flex items-center justify-center gap-3 rounded-xl border border-ink-100 bg-white p-12 text-sm text-ink-500 shadow-card">
      <span className="inline-block h-2.5 w-2.5 animate-pulse rounded-full bg-brand-600" />
      {label}
    </div>
  );
}

interface ErrorStateProps {
  message: string;
  onRetry?: () => void;
}

export function ErrorState({ message, onRetry }: ErrorStateProps) {
  return (
    <div className="rounded-xl border border-brand-200 bg-brand-50 p-6 text-sm text-brand-800 shadow-card">
      <p className="font-semibold">Something went wrong</p>
      <p className="mt-1">{message}</p>
      {onRetry && (
        <button
          type="button"
          onClick={onRetry}
          className="mt-3 rounded-md border border-brand-300 bg-white px-3 py-1.5 text-xs font-semibold text-brand-700 hover:bg-brand-100"
        >
          Try again
        </button>
      )}
    </div>
  );
}
