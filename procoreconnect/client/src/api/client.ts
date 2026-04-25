import axios from "axios";
import type {
  AuthResponse,
  Integration,
  IntegrationFormValues,
  LoginValues,
  RegisterValues,
  SyncLog,
  User,
  WebhookEvent,
} from "../types";

const baseURL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:3000";

export const TOKEN_STORAGE_KEY = "procoreconnect.token";

export const apiClient = axios.create({
  baseURL,
  headers: { "Content-Type": "application/json" },
  timeout: 10_000,
});

// Attach the JWT to every outgoing request when present.
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_STORAGE_KEY);
  if (token) {
    config.headers = config.headers ?? {};
    (config.headers as Record<string, string>).Authorization = `Bearer ${token}`;
  }
  return config;
});

// On 401 anywhere, drop the token and let the AuthContext detect the absence
// (via a custom event) so it can redirect to /login.
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem(TOKEN_STORAGE_KEY);
      window.dispatchEvent(new CustomEvent("auth:unauthorized"));
    }
    return Promise.reject(error);
  },
);

// --- Auth ---

export async function register(values: RegisterValues): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>("/api/v1/auth/register", values);
  return data;
}

export async function login(values: LoginValues): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>("/api/v1/auth/login", values);
  return data;
}

export async function me(): Promise<User> {
  const { data } = await apiClient.get<User>("/api/v1/auth/me");
  return data;
}

export async function logout(): Promise<void> {
  await apiClient.delete("/api/v1/auth/logout");
}

// --- Integrations ---

export async function listIntegrations(): Promise<Integration[]> {
  const { data } = await apiClient.get<Integration[]>("/api/v1/integrations");
  return data;
}

export async function getIntegration(id: number): Promise<Integration> {
  const { data } = await apiClient.get<Integration>(`/api/v1/integrations/${id}`);
  return data;
}

export async function createIntegration(values: IntegrationFormValues): Promise<Integration> {
  const { data } = await apiClient.post<Integration>("/api/v1/integrations", {
    integration: values,
  });
  return data;
}

export async function updateIntegration(
  id: number,
  values: Partial<IntegrationFormValues>,
): Promise<Integration> {
  const { data } = await apiClient.put<Integration>(`/api/v1/integrations/${id}`, {
    integration: values,
  });
  return data;
}

export async function deleteIntegration(id: number): Promise<void> {
  await apiClient.delete(`/api/v1/integrations/${id}`);
}

export async function listSyncLogs(integrationId: number): Promise<SyncLog[]> {
  const { data } = await apiClient.get<SyncLog[]>(
    `/api/v1/integrations/${integrationId}/sync_logs`,
  );
  return data;
}

export async function listWebhookEvents(integrationId: number): Promise<WebhookEvent[]> {
  const { data } = await apiClient.get<WebhookEvent[]>(
    `/api/v1/integrations/${integrationId}/webhook_events`,
  );
  return data;
}
