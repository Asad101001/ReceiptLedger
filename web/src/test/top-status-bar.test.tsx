import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { TopStatusBar } from '../features/status/TopStatusBar';
import { HealthResponse } from '../types';
import { useConsoleStore } from '../store/useConsoleStore';

const mockHealthy: HealthResponse = {
  status: 'ok',
  version: '1.0.0',
  environment: 'development',
  engines: {
    cloud_vision: 'ok (quota_remaining=950)',
    tesseract: 'ok',
    easyocr: 'ok (lazy-loaded)',
    gemini: 'ok (model=gemini-3.5-flash-lite)',
    database: 'supabase',
  },
};

describe('Phase 3: Top Status Bar & Engine Telemetry', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('renders brand header, console badge, and cloud synced status when healthy', () => {
    render(
      <TopStatusBar
        health={mockHealthy}
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
      />
    );

    expect(screen.getByText('ReceiptLedger')).toBeInTheDocument();
    expect(screen.getByText('Console')).toBeInTheDocument();
    expect(screen.getByText('Cloud Synced')).toBeInTheDocument();
    expect(screen.getByText('Admin, Audit & Human Triage')).toBeInTheDocument();
    expect(screen.getByText('operator@receiptledger.com')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Upload Receipt/i })).toBeInTheDocument();
  });

  it('renders system degraded status when an engine reports degraded or unavailable', () => {
    const degradedHealth: HealthResponse = {
      status: 'degraded',
      version: '1.0.0',
      environment: 'development',
      engines: {
        cloud_vision: 'unavailable',
        tesseract: 'ok',
        easyocr: 'ok',
        gemini: 'unavailable',
        database: 'sqlite',
      },
    };

    render(
      <TopStatusBar
        health={degradedHealth}
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
      />
    );

    expect(screen.getByText('System Degraded')).toBeInTheDocument();
  });

  it('renders synchronizing status indicator when health is loading', () => {
    render(
      <TopStatusBar
        isHealthLoading={true}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
      />
    );

    expect(screen.getByText('Synchronizing...')).toBeInTheDocument();
  });

  it('clearly labels offline demo mode when mock mode is active', () => {
    render(
      <TopStatusBar
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
        isMockMode={true}
      />
    );

    expect(screen.getByText('Offline Fixtures')).toBeInTheDocument();
  });

  it('triggers onLogout callback when sign out button is clicked', () => {
    const onLogout = vi.fn();
    render(
      <TopStatusBar
        health={mockHealthy}
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={onLogout}
      />
    );

    const logoutBtn = screen.getByTitle('Sign Out');
    fireEvent.click(logoutBtn);
    expect(onLogout).toHaveBeenCalledTimes(1);
  });

  it('triggers toggleUploadDrawer when Upload Receipt button is clicked', () => {
    const toggleUploadDrawer = vi.fn();
    useConsoleStore.setState({ toggleUploadDrawer });

    render(
      <TopStatusBar
        health={mockHealthy}
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
      />
    );

    const uploadBtn = screen.getByRole('button', { name: /Upload Receipt/i });
    fireEvent.click(uploadBtn);
    expect(toggleUploadDrawer).toHaveBeenCalledTimes(1);
  });

  it('strictly adheres to zero-gradient and zero-glassmorphism constraints', () => {
    const { container } = render(
      <TopStatusBar
        health={mockHealthy}
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
      />
    );

    expect(container.innerHTML).not.toContain('gradient');
    expect(container.innerHTML).not.toContain('backdrop-filter');
    expect(container.innerHTML).not.toContain('backdrop-blur');
  });
});
