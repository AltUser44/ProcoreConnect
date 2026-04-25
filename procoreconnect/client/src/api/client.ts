import axios from "axios";
import type {
  Integration,
  IntegrationFormValues,
  SyncLog,
  WebhookEvent,
} from "../types";

const baseURL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:3000";

export const apiClient = axios.create({
  baseURL,
  headers: { "Content-Type": "application/json" },
  timeout: 10_000,
});

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
