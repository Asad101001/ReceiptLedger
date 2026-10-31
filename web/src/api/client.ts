import {
  AuthResponse,
  AuthResponseSchema,
  DashboardOverviewResponse,
  DashboardOverviewResponseSchema,
  DashboardSeedResponse,
  DashboardSeedResponseSchema,
  HealthResponse,
  HealthResponseSchema,
  LoginRequest,
  PaginatedReceiptsResponse,
  PaginatedReceiptsResponseSchema,
  ResetResponse,
  ResetResponseSchema,
  ReviewQueueItem,
  ReviewQueueItemSchema,
  ReviewQueueResolveRequest,
  ReviewQueueResolveResponse,
  ReviewQueueResolveResponseSchema,
  ReviewStatus,
  SystemRunLog,
  SystemRunLogSchema,
  TrendResponse,
  TrendResponseSchema,
  UserSession,
  UserSessionSchema,
} from '../types';
import { adaptReceipt, adaptReviewQueueItem } from '../lib/adapter';
import { z } from 'zod';

const API_URL_STORAGE_KEY = 'receiptledger_api_base_url';

export const getApiBaseUrl = (): string => {
  if (typeof localStorage !== 'undefined') {
    const stored = localStorage.getItem(API_URL_STORAGE_KEY);
    if (stored && stored.trim()) {
      return stored.trim().replace(/\/+$/, '');
    }
  }
  const envUrl = import.meta.env.VITE_API_BASE_URL;
  if (envUrl && envUrl.trim()) {
    return envUrl.trim().replace(/\/+$/, '');
  }
  return 'http://localhost:8000/api/v1';
};

export const setApiBaseUrl = (url: string | null): void => {
  if (typeof localStorage === 'undefined') return;
  if (url && url.trim()) {
    localStorage.setItem(API_URL_STORAGE_KEY, url.trim().replace(/\/+$/, ''));
  } else {
    localStorage.removeItem(API_URL_STORAGE_KEY);
  }
};

export const API_BASE_URL = getApiBaseUrl();

export class ApiError extends Error {
  public status: number;
  public data: unknown;

  constructor(message: string, status: number, data?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

// Token management
const TOKEN_STORAGE_KEY = 'receiptledger_access_token';

export const getAuthToken = (): string | null => {
  if (typeof localStorage === 'undefined') return null;
  const token = localStorage.getItem(TOKEN_STORAGE_KEY);
  // Safety: never return dev_mock tokens as real access tokens
  if (token && token.startsWith('dev_mock')) return null;
  return token;
};

export const setAuthToken = (token: string | null): void => {
  if (typeof localStorage === 'undefined') return;
  // Safety: never persist dev_mock tokens under receiptledger_access_token
  if (token && !token.startsWith('dev_mock')) {
    localStorage.setItem(TOKEN_STORAGE_KEY, token);
  } else {
    localStorage.removeItem(TOKEN_STORAGE_KEY);
  }
};

/**
 * Standard fetch wrapper with auth header injection, typed error handling,
 * and Zod validation.
 */
async function apiRequest<T>(
  endpoint: string,
  schema: z.ZodType<T>,
  options: RequestInit = {}
): Promise<T> {
  const token = getAuthToken();
  const baseUrl = getApiBaseUrl();
  const url = `${baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

  const headers: Record<string, string> = {
    Accept: 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (!(options.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
  }

  // Safety: never transmit dev_mock identifiers as Bearer tokens to APIs
  if (token && typeof token === 'string' && !token.startsWith('dev_mock')) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  let response: Response;
  try {
    response = await fetch(url, {
      ...options,
      headers,
    });
  } catch (fetchError: unknown) {
    const errorDetail = fetchError instanceof Error ? fetchError.message : String(fetchError);
    throw new ApiError(
      `Gateway connection unavailable (${baseUrl}). Ensure the backend server is running. (${errorDetail})`,
      0,
      fetchError
    );
  }

  if (response.status === 401) {
    // Session expired or invalid
    setAuthToken(null);
    let detailMsg = 'Authentication required. Session expired or invalid.';
    try {
      const errJson = await response.json();
      if (errJson && typeof errJson === 'object' && 'detail' in errJson) {
        detailMsg = String(errJson.detail);
      }
    } catch {
      // Keep default session expired message
    }
    throw new ApiError(detailMsg, 401);
  }

  if (!response.ok) {
    let errorPayload: unknown;
    try {
      errorPayload = await response.json();
    } catch {
      errorPayload = await response.text();
    }
    const message =
      typeof errorPayload === 'object' && errorPayload !== null && 'detail' in errorPayload
        ? String((errorPayload as { detail: unknown }).detail)
        : `Request failed with status ${response.status}`;
    throw new ApiError(message, response.status, errorPayload);
  }

  const json = await response.json();
  const parsed = schema.safeParse(json);
  if (!parsed.success) {
    console.warn(`[API] Schema validation issue on ${endpoint}:`, parsed.error.issues);
    // Return json if schema has subtle optional field difference to remain resilient
    return json as T;
  }
  return parsed.data;
}

// ── API Gateway Methods ───────────────────────────────────────────────────────

export const api = {
  // ── Authentication ─────────────────────────────────────────────────────────
  async login(credentials: LoginRequest): Promise<AuthResponse> {
    const res = await apiRequest('/auth/login', AuthResponseSchema, {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
    setAuthToken(res.access_token);
    return res;
  },

  async getCurrentUser(): Promise<UserSession> {
    return apiRequest('/auth/me', UserSessionSchema);
  },

  logout(): void {
    setAuthToken(null);
  },

  // ── System Health ──────────────────────────────────────────────────────────
  async getHealth(): Promise<HealthResponse> {
    return apiRequest('/health', HealthResponseSchema);
  },

  // ── Dashboard Overview & KPIs ──────────────────────────────────────────────
  async getDashboardOverview(year = 2026, month = 10): Promise<DashboardOverviewResponse> {
    return apiRequest(
      `/dashboard/overview?year=${year}&month=${month}`,
      DashboardOverviewResponseSchema
    );
  },

  // ── Review Queue ───────────────────────────────────────────────────────────
  async getReviewQueue(statusFilter: ReviewStatus = 'UNRESOLVED'): Promise<ReviewQueueItem[]> {
    const items = await apiRequest(
      `/review-queue?status_filter=${statusFilter}`,
      z.array(ReviewQueueItemSchema)
    );
    return items.map(adaptReviewQueueItem);
  },

  async resolveReviewItem(
    queueId: string,
    payload: ReviewQueueResolveRequest
  ): Promise<ReviewQueueResolveResponse> {
    return apiRequest(
      `/review-queue/${queueId}`,
      ReviewQueueResolveResponseSchema,
      {
        method: 'PATCH',
        body: JSON.stringify(payload),
      }
    );
  },

  // ── Ingestion Audit Ledger ─────────────────────────────────────────────────
  async getReceipts(params: {
    page?: number;
    pageSize?: number;
    search?: string;
  } = {}): Promise<PaginatedReceiptsResponse> {
    const page = params.page || 1;
    const pageSize = params.pageSize || 25;
    let url = `/analytics/receipts?page=${page}&page_size=${pageSize}`;
    if (params.search && params.search.trim()) {
      url += `&search=${encodeURIComponent(params.search.trim())}`;
    }

    const data = await apiRequest(url, PaginatedReceiptsResponseSchema);
    return {
      ...data,
      receipts: data.receipts.map(adaptReceipt),
    };
  },

  // ── Telemetry & Trends ─────────────────────────────────────────────────────
  async getTrends(months = 6): Promise<TrendResponse> {
    return apiRequest(`/analytics/trends?months=${months}`, TrendResponseSchema);
  },

  async getSystemRuns(limit = 20): Promise<SystemRunLog[]> {
    return apiRequest(`/system/runs?limit=${limit}`, z.array(SystemRunLogSchema));
  },

  // ── Testing Controls: Seed & Reset ─────────────────────────────────────────
  async seedDemoData(): Promise<DashboardSeedResponse> {
    return apiRequest('/dashboard/seed-demo', DashboardSeedResponseSchema, {
      method: 'POST',
    });
  },

  async resetLedger(): Promise<ResetResponse> {
    return apiRequest('/dashboard/reset', ResetResponseSchema, {
      method: 'POST',
    });
  },

  // ── Receipt Upload & Duplicate Detection ───────────────────────────────────
  async uploadReceipt(file: File, ocrEngine = 'auto'): Promise<{
    status: number;
    ok: boolean;
    data: unknown;
  }> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('ocr_engine', ocrEngine);
    formData.append('device_timestamp', new Date().toISOString());
    formData.append('capture_mode', 'single');

    const token = getAuthToken();
    const headers: Record<string, string> = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(`${getApiBaseUrl()}/receipts/upload`, {
      method: 'POST',
      headers,
      body: formData,
    });

    let data: unknown;
    try {
      data = await res.json();
    } catch {
      data = await responseTextFallback(res);
    }

    return {
      status: res.status, // 200 = Success, 409 = Duplicate Conflict, 422 = Unprocessable
      ok: res.ok,
      data,
    };
  },

  // ── Asset & Media URLs ─────────────────────────────────────────────────────
  getReceiptImageUrl(receiptId: string): string {
    return `${getApiBaseUrl()}/receipts/${receiptId}/image`;
  },

  getReviewCropUrl(queueId: string): string {
    return `${getApiBaseUrl()}/review-queue/${queueId}/crop`;
  },

  getExportCsvUrl(year = 2026, month = 10): string {
    return `${getApiBaseUrl()}/analytics/export?format=csv&year=${year}&month=${month}`;
  },
};

async function responseTextFallback(res: Response): Promise<string> {
  try {
    return await res.text();
  } catch {
    return '';
  }
}
