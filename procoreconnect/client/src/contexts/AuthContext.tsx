import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  TOKEN_STORAGE_KEY,
  login as apiLogin,
  logout as apiLogout,
  me as apiMe,
  register as apiRegister,
} from "../api/client";
import type { LoginValues, RegisterValues, User } from "../types";

type AuthStatus = "loading" | "authenticated" | "unauthenticated";

interface AuthContextValue {
  status: AuthStatus;
  user: User | null;
  login: (values: LoginValues) => Promise<void>;
  register: (values: RegisterValues) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [status, setStatus] = useState<AuthStatus>("loading");

  // jwt in localStorage; /me fails → drop token, back to unauthed
  const bootstrap = useCallback(async () => {
    const token = localStorage.getItem(TOKEN_STORAGE_KEY);
    if (!token) {
      setStatus("unauthenticated");
      return;
    }
    try {
      const fetched = await apiMe();
      setUser(fetched);
      setStatus("authenticated");
    } catch {
      localStorage.removeItem(TOKEN_STORAGE_KEY);
      setUser(null);
      setStatus("unauthenticated");
    }
  }, []);

  useEffect(() => {
    bootstrap();
  }, [bootstrap]);

  // The axios interceptor dispatches this event on any 401, letting us drop
  // user state without needing every caller to coordinate with us.
  useEffect(() => {
    const handler = () => {
      setUser(null);
      setStatus("unauthenticated");
    };
    window.addEventListener("auth:unauthorized", handler);
    return () => window.removeEventListener("auth:unauthorized", handler);
  }, []);

  const login = useCallback(async (values: LoginValues) => {
    const { token, user: u } = await apiLogin(values);
    localStorage.setItem(TOKEN_STORAGE_KEY, token);
    setUser(u);
    setStatus("authenticated");
  }, []);

  const register = useCallback(async (values: RegisterValues) => {
    const { token, user: u } = await apiRegister(values);
    localStorage.setItem(TOKEN_STORAGE_KEY, token);
    setUser(u);
    setStatus("authenticated");
  }, []);

  const logout = useCallback(async () => {
    try {
      await apiLogout();
    } catch {
      // Ignore — server logout is best-effort with stateless JWTs.
    }
    localStorage.removeItem(TOKEN_STORAGE_KEY);
    setUser(null);
    setStatus("unauthenticated");
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({ status, user, login, register, logout }),
    [status, user, login, register, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
