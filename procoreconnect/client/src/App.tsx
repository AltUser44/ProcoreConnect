import { BrowserRouter, Link, NavLink, Route, Routes } from "react-router-dom";
import { Dashboard } from "./pages/Dashboard";
import { IntegrationDetail } from "./pages/IntegrationDetail";
import { NewIntegration } from "./pages/NewIntegration";
import { HexLogo } from "./components/HexLogo";

function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-full">
      <header className="sticky top-0 z-10 border-b border-ink-100 bg-white/95 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <Link to="/" className="flex items-center gap-3">
            <HexLogo size={36} />
            <div className="flex flex-col leading-none">
              <span className="text-lg font-bold tracking-tight text-ink-900">
                ProcoreConnect
              </span>
              <span className="mt-0.5 text-[11px] font-medium uppercase tracking-widest text-ink-400">
                Integration Platform
              </span>
            </div>
          </Link>
          <nav className="flex items-center gap-1 text-sm font-medium">
            <NavLink
              to="/"
              end
              className={({ isActive }) =>
                `rounded-md px-3 py-2 transition ${
                  isActive
                    ? "text-ink-900"
                    : "text-ink-500 hover:text-ink-900"
                }`
              }
            >
              Dashboard
            </NavLink>
            <Link
              to="/integrations/new"
              className="ml-2 inline-flex items-center gap-1.5 rounded-md bg-brand-600 px-4 py-2 font-semibold text-white shadow-sm transition hover:bg-brand-700"
            >
              <span className="text-base leading-none">+</span> New integration
            </Link>
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-7xl px-6 py-10">{children}</main>
      <footer className="border-t border-ink-100 bg-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4 text-xs text-ink-400">
          <span>ProcoreConnect — bridging your systems with the world.</span>
          <span>v0.1</span>
        </div>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/integrations/new" element={<NewIntegration />} />
          <Route path="/integrations/:id" element={<IntegrationDetail />} />
          <Route path="*" element={<Dashboard />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}
