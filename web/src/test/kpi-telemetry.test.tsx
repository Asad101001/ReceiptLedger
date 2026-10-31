import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { KpiMetricsRow } from '../features/kpi/KpiMetricsRow';
import { mockOverviewResponse } from './mocks/handlers';
import { DashboardOverviewResponse } from '../types';

describe('KPI Metrics Row & Formatting', () => {
  it('renders all 4 KPI cards with PKR en-PK formatting and percentage change', () => {
    render(<KpiMetricsRow overview={mockOverviewResponse} isLoading={false} />);

    // Card 1: Total Ingested
    expect(screen.getByText('TOTAL INGESTED')).toBeInTheDocument();
    expect(screen.getByText('148 Receipts')).toBeInTheDocument();
    expect(screen.getByText('+14%')).toBeInTheDocument();

    // Card 2: Total Reconciled Spend
    expect(screen.getByText('TOTAL RECONCILED SPEND')).toBeInTheDocument();
    expect(screen.getByText('PKR 184,250.00')).toBeInTheDocument();
    expect(screen.getByText('en-PK')).toBeInTheDocument();

    // Card 3: Human Review Queue
    expect(screen.getByText('HUMAN REVIEW QUEUE')).toBeInTheDocument();
    expect(screen.getByText(/7 Pending/)).toBeInTheDocument();

    // Card 4: AI Extraction Accuracy
    expect(screen.getByText('AI EXTRACTION ACCURACY')).toBeInTheDocument();
    expect(screen.getByText('96.2%')).toBeInTheDocument();
  });

  it('renders clean zero-state values after ledger reset', () => {
    const zeroOverview: DashboardOverviewResponse = {
      ...mockOverviewResponse,
      total_spend: 0,
      receipt_count: 0,
      pending_review_count: 0,
      delta_percentage: null,
      stat_cards: [
        {
          key: 'accuracy',
          label: 'AI EXTRACTION ACCURACY',
          value: 0,
          formatted_value: '0%',
          change: null,
          change_type: 'neutral',
        },
      ],
    };

    render(<KpiMetricsRow overview={zeroOverview} isLoading={false} />);

    expect(screen.getByText('0 Receipts')).toBeInTheDocument();
    expect(screen.getByText('PKR 0.00')).toBeInTheDocument();
    expect(screen.getByText(/0 Pending/)).toBeInTheDocument();
  });

  it('renders solid grey skeleton blocks without gradients during loading', () => {
    const { container } = render(<KpiMetricsRow isLoading={true} />);

    // Should contain 4 skeleton cards with solid grey backgrounds (bg-slate-200, bg-slate-300)
    const skeletons = container.querySelectorAll('.bg-slate-200, .bg-slate-300');
    expect(skeletons.length).toBeGreaterThanOrEqual(8);

    // Ensure zero gradient classes
    expect(container.innerHTML).not.toContain('gradient');
    expect(container.innerHTML).not.toContain('backdrop-filter');
  });
});
