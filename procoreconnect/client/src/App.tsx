import { BrowserRouter, Link, NavLink, Route, Routes, useNavigate } from "react-router-dom";
import { Dashboard } from "./pages/Dashboard";
import { IntegrationDetail } from "./pages/IntegrationDetail";
import { NewIntegration } from "./pages/NewIntegration";
import { Login } from "./pages/Login";
import { Register } from "./pages/Register";
import { About } from "./pages/About";
import { Privacy } from "./pages/Privacy";
import { Terms } from "./pages/Terms";
import { NotFound } from "./pages/NotFound";
import { HexLogo } from "./components/HexLogo";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { AuthProvider, useAuth } from "./contexts/AuthContext";

function Layout({ children }: { children: React.ReactNode }) {
  const { status, user, logout } = useAuth();
  const navigate = useNavigate();

  const isAuthed = status === "authenticated";

  async function handleLogout() {
    await logout();
    navigate("/login", { replace: true });
  }

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

          {isAuthed ? (
            <nav className="flex items-center gap-4 text-sm font-medium">
              <NavLink
                to="/"
                end
                className={({ isActive }) =>
                  `rounded-md px-3 py-2 transition ${
                    isActive ? "text-ink-900" : "text-ink-500 hover:text-ink-900"
                  }`
                }
              >
                Dashboard
              </NavLink>
              <Link
                to="/integrations/new"
                className="inline-flex items-center gap-1.5 rounded-md bg-brand-600 px-4 py-2 font-semibold text-white shadow-sm transition hover:bg-brand-700"
              >
                <span className="text-base leading-none">+</span> New
              </Link>
              <div className="ml-2 flex items-center gap-3 border-l border-ink-100 pl-4">
                <div className="flex items-center gap-2">
                  <span className="grid h-8 w-8 place-items-center rounded-full bg-ink-100 text-xs font-semibold text-ink-700">
                    {user?.email.charAt(0).toUpperCase() ?? "?"}
                  </span>
                  <span className="hidden text-sm text-ink-600 sm:inline">
                    {user?.email}
                  </span>
                </div>
                <button
                  type="button"
                  onClick={handleLogout}
                  className="rounded-md border border-ink-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700 transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700"
                >
                  Sign out
                </button>
              </div>
            </nav>
          ) : (
            <nav className="flex items-center gap-2 text-sm font-medium">
              <NavLink
                to="/login"
                className={({ isActive }) =>
                  `rounded-md px-3 py-2 transition ${
                    isActive ? "text-ink-900" : "text-ink-500 hover:text-ink-900"
                  }`
                }
              >
                Sign in
              </NavLink>
              <Link
                to="/register"
                className="rounded-md bg-brand-600 px-4 py-2 font-semibold text-white shadow-sm transition hover:bg-brand-700"
              >
                Get started
              </Link>
            </nav>
          )}
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-6 py-10">{children}</main>

      <footer className="border-t border-ink-100 bg-white">
        <div className="mx-auto flex max-w-7xl flex-col gap-3 px-6 py-4 text-xs text-ink-400 sm:flex-row sm:items-center sm:justify-between">
          <span>ProcoreConnect — bridging your systems with the world.</span>
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1">
            <Link to="/about" className="font-medium text-ink-500 hover:text-brand-600 hover:underline">
              About
            </Link>
            <Link
              to="/privacy"
              className="font-medium text-ink-500 hover:text-brand-600 hover:underline"
            >
              Privacy
            </Link>
            <Link to="/terms" className="font-medium text-ink-500 hover:text-brand-600 hover:underline">
              Terms
            </Link>
            <span className="text-ink-300 sm:ml-2">v0.2</span>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Layout>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/about" element={<About />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/terms" element={<Terms />} />

            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }
            />
            <Route
              path="/integrations/new"
              element={
                <ProtectedRoute>
                  <NewIntegration />
                </ProtectedRoute>
              }
            />
            <Route
              path="/integrations/:id"
              element={
                <ProtectedRoute>
                  <IntegrationDetail />
                </ProtectedRoute>
              }
            />
            {/* Public: unknown paths must not use ProtectedRoute or guests get sent to /login
                (and old bundles without /about etc. would match * before those routes existed). */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Layout>
      </AuthProvider>
    </BrowserRouter>
  );
}
