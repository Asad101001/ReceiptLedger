/**
 * @vitest-environment node
 */
import { describe, it, expect } from 'vitest';
import { api } from '../api/client';

describe('API Gateway Contracts & MSW Integration (Node Environment)', () => {
  it('authenticates with valid credentials and receives JWT', async () => {
    const res = await api.login({ email: 'user@receiptledger.com', password: 'demo1234' });
    expect(res.access_token).toBe('mock-jwt-token-2026');
    expect(res.user.email).toBe('user@receiptledger.com');
    expect(res.user.role).toBe('admin');
  });

  it('rejects invalid credentials with 401 and returns detail message', async () => {
    await expect(
      api.login({ email: 'wrong@receiptledger.com', password: 'wrong' })
    ).rejects.toThrow(/Invalid email or password/i);
  });

  it('fetches current user session', async () => {
    const user = await api.getCurrentUser();
    expect(user.email).toBe('user@receiptledger.com');
    expect(user.is_authenticated).toBe(true);
  });

  it('fetches system health engines', async () => {
    const health = await api.getHealth();
    expect(health.status).toBe('ok');
    expect(health.engines.cloud_vision).toContain('quota_remaining=950');
    expect(health.engines.database).toBe('supabase');
  });

  it('fetches dashboard overview and spend stats', async () => {
    const overview = await api.getDashboardOverview(2026, 10);
    expect(overview.total_spend).toBe(184250.0);
    expect(overview.stat_cards).toHaveLength(4);
    expect(overview.stat_cards[1].formatted_value).toBe('148 Receipts');
  });

  it('fetches review queue items', async () => {
    const queue = await api.getReviewQueue();
    expect(queue.length).toBeGreaterThan(0);
    expect(queue[0].merchant_name).toBe('Chaudhry Sabzi & Fruit Store');
  });

  it('resolves review item via PATCH', async () => {
    const res = await api.resolveReviewItem('rev_demo_01', {
      action: 'ACCEPTED',
      confirmed_name: 'Sweet Melon',
    });
    expect(res.id).toBe('rev_demo_01');
    expect(res.review_status).toBe('ACCEPTED');
  });

  it('fetches paginated receipts', async () => {
    const receipts = await api.getReceipts({ page: 1, pageSize: 25 });
    expect(receipts.receipts.length).toBeGreaterThan(0);
    expect(receipts.receipts[0].merchant_name).toBe('Chaudhry Sabzi & Fruit Store');
  });

  it('fetches system runs telemetry', async () => {
    const runs = await api.getSystemRuns();
    expect(runs.length).toBeGreaterThan(0);
    expect(runs[0].run_id).toBe('fd26320d-116d-4c06-b111-089f581c444d');
    expect(runs[0].descriptor).toBe('gemini_flash_lite_evaluation_run');
  });

  it('triggers seed demo and store reset', async () => {
    const seedRes = await api.seedDemoData();
    expect(seedRes.status).toBe('success');
    expect(seedRes.receipts_count).toBe(148);

    const resetRes = await api.resetLedger();
    expect(resetRes.status).toBe('success');
  });
});
