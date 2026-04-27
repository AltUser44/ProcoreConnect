import { Link } from "react-router-dom";

export function StaticInfoPage({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mx-auto max-w-3xl pb-16">
      <p className="text-sm text-ink-500">
        <Link to="/" className="font-semibold text-brand-600 hover:underline">
          Home
        </Link>
        <span className="mx-2 text-ink-300">·</span>
        <Link to="/login" className="font-semibold text-brand-600 hover:underline">
          Sign in
        </Link>
      </p>
      <h1 className="mt-6 text-3xl font-bold tracking-tight text-ink-900">{title}</h1>
      <div className="mt-10 space-y-6 text-sm leading-relaxed text-ink-700">{children}</div>
    </div>
  );
}

export function StaticSection({
  heading,
  children,
}: {
  heading: string;
  children: React.ReactNode;
}) {
  return (
    <section className="space-y-3">
      <h2 className="text-base font-semibold text-ink-900">{heading}</h2>
      <div className="space-y-3">{children}</div>
    </section>
  );
}
