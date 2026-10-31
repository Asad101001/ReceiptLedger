import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { TopStatusBar } from '../features/status/TopStatusBar';
import { HealthResponse } from '../types';

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
  it('renders all engines operational status with Cloud Vision quota remaining', () => {
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

    // Master operational status
    expect(screen.getByText('ALL ENGINES OPERATIONAL')).toBeInTheDocument();

    // Engine chips
    expect(screen.getByText('GEMINI AI')).toBeInTheDocument();
    expect(screen.getByText('CLOUD VISION')).toBeInTheDocument();
    expect(screen.getByText('(950 quota)')).toBeInTheDocument();
    expect(screen.getByText('SUPABASE')).toBeInTheDocument();
    expect(screen.getByText('TESSERACT')).toBeInTheDocument();
    expect(screen.getByText('EASYOCR')).toBeInTheDocument();

    // User profile
    expect(screen.getByText('operator@receiptledger.com')).toBeInTheDocument();
  });

  it('renders degraded status when an engine reports degraded or low quota', () => {
    const degradedHealth: HealthResponse = {
      status: 'degraded',
      version: '1.0.0',
      environment: 'development',
      engines: {
        cloud_vision: 'degraded (quota_remaining=25)',
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

    expect(screen.getByText('ENGINES DEGRADED')).toBeInTheDocument();
    expect(screen.getByText('(25 quota)')).toBeInTheDocument();
    expect(screen.getByText('DATABASE')).toBeInTheDocument();
  });

  it('clearly labels offline demo mode when backend is unreachable or mock mode is active', () => {
    render(
      <TopStatusBar
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="user@receiptledger.com"
        onLogout={vi.fn()}
        isMockMode={true}
      />
    );

    expect(screen.getByText('OFFLINE DEMO METRICS (MOCK)')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Reload Mock Queue/i })).toBeInTheDocument();
  });

  it('renders Offline Dev Mode button when degraded and callback is provided', () => {
    const onEnterDevMock = vi.fn();
    render(
      <TopStatusBar
        health={{
          status: 'degraded',
          version: '1.0.0',
          environment: 'development',
          engines: {
            cloud_vision: 'unavailable',
            tesseract: 'ok',
            easyocr: 'ok',
            gemini: 'unavailable',
            database: 'unavailable',
          },
        }}
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
        isMockMode={false}
        onEnterDevMockMode={onEnterDevMock}
      />
    );

    const offlineBtn = screen.getByRole('button', { name: /Offline Dev Mode/i });
    expect(offlineBtn).toBeInTheDocument();
    fireEvent.click(offlineBtn);
    expect(onEnterDevMock).toHaveBeenCalledTimes(1);
  });

  it('triggers inline two-step reset confirmation without modal popups', async () => {
    const onResetLedger = vi.fn().mockResolvedValue(undefined);

    render(
      <TopStatusBar
        health={mockHealthy}
        isHealthLoading={false}
        onSeedDemo={vi.fn()}
        onResetLedger={onResetLedger}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
      />
    );

    // Initial state: "Reset Ledger" button visible, no confirm button yet
    const resetBtn = screen.getByRole('button', { name: /Reset Ledger/i });
    expect(resetBtn).toBeInTheDocument();
    expect(screen.queryByText('Confirm Reset?')).not.toBeInTheDocument();

    // Step 1: Click "Reset Ledger"
    fireEvent.click(resetBtn);

    // Must show inline confirm and cancel buttons (NO modal!)
    const confirmBtn = screen.getByRole('button', { name: /Confirm Reset\?/i });
    const cancelBtn = screen.getByRole('button', { name: /Cancel/i });
    expect(confirmBtn).toBeInTheDocument();
    expect(cancelBtn).toBeInTheDocument();

    // Step 2: Cancel should revert to original state
    fireEvent.click(cancelBtn);
    expect(screen.getByRole('button', { name: /Reset Ledger/i })).toBeInTheDocument();
    expect(screen.queryByText('Confirm Reset?')).not.toBeInTheDocument();
    expect(onResetLedger).not.toHaveBeenCalled();

    // Step 3: Click reset again and confirm
    fireEvent.click(screen.getByRole('button', { name: /Reset Ledger/i }));
    fireEvent.click(screen.getByRole('button', { name: /Confirm Reset\?/i }));
    expect(onResetLedger).toHaveBeenCalledTimes(1);
  });

  it('triggers Seed Demo callback', () => {
    const onSeedDemo = vi.fn().mockResolvedValue(undefined);

    render(
      <TopStatusBar
        health={mockHealthy}
        isHealthLoading={false}
        onSeedDemo={onSeedDemo}
        onResetLedger={vi.fn()}
        isSeeding={false}
        isResetting={false}
        userEmail="operator@receiptledger.com"
        onLogout={vi.fn()}
      />
    );

    const seedBtn = screen.getByRole('button', { name: /Seed Demo \(148\)/i });
    fireEvent.click(seedBtn);
    expect(onSeedDemo).toHaveBeenCalledTimes(1);
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
