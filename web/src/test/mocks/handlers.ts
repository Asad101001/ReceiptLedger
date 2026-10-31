import { http, HttpResponse } from 'msw';
import {
  mockHealthResponse,
  mockOverviewResponse,
  mockReviewQueue,
  mockReceipts,
  mockTrends,
  mockSystemRuns,
} from '../../lib/mockData';

export {
  mockHealthResponse,
  mockOverviewResponse,
  mockReviewQueue,
  mockReceipts,
  mockTrends,
  mockSystemRuns,
};

export const handlers = [
  // ── Auth ──────────────────────────────────────────────────────────────────
  http.post('*/api/v1/auth/login', async ({ request }) => {
    const body = (await request.json()) as { email: string; password: string };
    if (body.email === 'user@receiptledger.com' && body.password === 'demo1234') {
      return HttpResponse.json({
        access_token: 'mock-jwt-token-2026',
        token_type: 'bearer',
        expires_in: 86400,
        user: {
          user_id: 'usr_demo_7721',
          email: 'user@receiptledger.com',
          full_name: 'Demo Household Manager',
          role: 'admin',
          is_authenticated: true,
        },
      });
    }
    return HttpResponse.json({ detail: 'Invalid email or password.' }, { status: 401 });
  }),

  http.get('*/api/v1/auth/me', () => {
    return HttpResponse.json({
      user_id: 'usr_demo_7721',
      email: 'user@receiptledger.com',
      full_name: 'Demo Household Manager',
      role: 'admin',
      is_authenticated: true,
    });
  }),

  // ── Health ────────────────────────────────────────────────────────────────
  http.get('*/api/v1/health', () => {
    return HttpResponse.json(mockHealthResponse);
  }),

  // ── Overview ──────────────────────────────────────────────────────────────
  http.get('*/api/v1/dashboard/overview', () => {
    return HttpResponse.json(mockOverviewResponse);
  }),

  // ── Review Queue ──────────────────────────────────────────────────────────
  http.get('*/api/v1/review-queue', () => {
    return HttpResponse.json(mockReviewQueue);
  }),

  http.patch('*/api/v1/review-queue/:id', async ({ params, request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json({
      id: params.id,
      line_item_id: '93b118b5-12ea-44d5-8bc2-a5d6f1406541',
      review_status: body.action || 'ACCEPTED',
      candidate_text: body.confirmed_name,
      model_confidence: 1.0,
    });
  }),

  // ── Analytics Receipts ────────────────────────────────────────────────────
  http.get('*/api/v1/analytics/receipts', () => {
    return HttpResponse.json({
      total: mockReceipts.length,
      page: 1,
      page_size: 25,
      total_pages: 1,
      receipts: mockReceipts,
    });
  }),

  // ── Trends ────────────────────────────────────────────────────────────────
  http.get('*/api/v1/analytics/trends', () => {
    return HttpResponse.json(mockTrends);
  }),

  // ── System Runs ───────────────────────────────────────────────────────────
  http.get('*/api/v1/system/runs', () => {
    return HttpResponse.json(mockSystemRuns);
  }),

  // ── Seed Demo & Reset ─────────────────────────────────────────────────────
  http.post('*/api/v1/dashboard/seed-demo', () => {
    return HttpResponse.json({
      status: 'success',
      message: 'Demo receipts seeded successfully.',
      receipts_count: 148,
      line_items_count: 377,
      review_items_count: 7,
    });
  }),

  http.post('*/api/v1/dashboard/reset', () => {
    return HttpResponse.json({
      status: 'success',
      message: 'Store reset to clean initial state.',
    });
  }),
];
