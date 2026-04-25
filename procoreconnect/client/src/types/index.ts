export type IntegrationStatus = "active" | "paused" | "error";

export interface Integration {
  id: number;
  name: string;
  status: IntegrationStatus;
  webhook_url: string | null;
  webhook_secret: string;
  api_endpoint: string;
  last_synced_at: string | null;
  sync_logs_count: number;
  pending_webhook_events_count: number;
  created_at: string;
  updated_at: string;
}

export type SyncLogStatus = "pending" | "success" | "failed";

export interface SyncLog {
  id: number;
  integration_id: number;
  event_type: string;
  status: SyncLogStatus;
  response_code: number | null;
  error_message: string | null;
  payload: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface WebhookEvent {
  id: number;
  integration_id: number;
  event_type: string;
  payload: Record<string, unknown>;
  processed: boolean;
  processed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface IntegrationFormValues {
  name: string;
  api_endpoint: string;
  api_key?: string;
  webhook_url?: string;
  status?: IntegrationStatus;
}

export interface ApiErrorBody {
  error?: string;
  errors?: string[];
}

export interface User {
  id: number;
  email: string;
  created_at: string;
  updated_at: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface LoginValues {
  email: string;
  password: string;
}

export interface RegisterValues {
  email: string;
  password: string;
  password_confirmation: string;
}
