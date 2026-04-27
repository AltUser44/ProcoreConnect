import { Link } from "react-router-dom";

export function NotFound() {
  return (
    <div className="mx-auto max-w-md rounded-2xl border border-ink-100 bg-white p-8 text-center shadow-card">
      <h1 className="text-xl font-bold text-ink-900">Page not found</h1>
      <p className="mt-2 text-sm text-ink-500">
        That URL doesn’t exist or this app build is out of date. Try home or sign in.
      </p>
      <div className="mt-6 flex flex-wrap justify-center gap-3 text-sm font-semibold">
        <Link to="/" className="text-brand-600 hover:underline">
          Home
        </Link>
        <Link to="/login" className="text-brand-600 hover:underline">
          Sign in
        </Link>
        <Link to="/about" className="text-brand-600 hover:underline">
          About
        </Link>
      </div>
    </div>
  );
}
