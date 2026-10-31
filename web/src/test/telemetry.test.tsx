import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { BottomRibbon } from '../features/telemetry/BottomRibbon';
import { CategorySpendDetail, MonthlyTrendPoint, SystemRunLog } from '../types';

const sampleCategories: CategorySpendDetail[] = [
  {
    category_name: 'Groceries & Food',
    color_hex: '#10B981',
    description: 'Staples, dairy, flour, produce, and fresh meat',
    total_spend: 88400.0,
    item_count: 210,
    percentage_of_total: 47.98,
  },
  {
    category_name: 'Household & Cleaning',
    color_hex: '#3B82F6',
    description: 'Detergents, cleaning supplies, and paper goods',
    total_spend: 32100.0,
    item_count: 75,
    percentage_of_total: 17.42,
  },
  {
    category_name: 'Utilities & Bills',
    color_hex: '#F59E0B',
    description: 'Electricity, gas, water, and internet bills',
    total_spend: 25000.0,
    item_count: 5,
    percentage_of_total: 13.57,
  },
];

const sampleTrends: MonthlyTrendPoint[] = [
  { period: '2026-07', total_spend: 148900, category_breakdown: {} },
  { period: '2026-08', total_spend: 159100, category_breakdown: {} },
  { period: '2026-09', total_spend: 161620, category_breakdown: {} },
  { period: '2026-10', total_spend: 184250, category_breakdown: {} },
];

const sampleRuns: SystemRunLog[] = [
  {
    run_id: 'fd26320d-116d-4c06-b111-089f581c444d',
    filename: '20261021_015459_gemini_flash_lite_evaluation_run.json',
    descriptor: 'gemini_flash_lite_evaluation_run',
    timestamp: '2026-10-21T01:54:59Z',
    metrics: {
      total_records: 148,
      success_count: 141,
      failure_count: 7,
      accuracy_percentage: 96.2,
      average_latency_ms: 385,
      p95_latency_ms: 610,
      model: 'gemini-3.5-flash-lite',
    },
    metadata: {
      pipeline: 'OpenCV Deskew -> Perceptual Hash -> Gemini Vision -> NLP Normalizer',
      summary: '148 receipts evaluated. Accuracy 96.2%.',
    },
    records_count: 148,
    size_kb: 4.8,
  },
  {
    run_id: '8b192e44-d130-4e89-9a71-678cba0123ef',
    filename: '20261020_142010_cloud_vision_hybrid_benchmark.json',
    descriptor: 'cloud_vision_hybrid_benchmark',
    timestamp: '2026-10-20T14:20:10Z',
    metrics: {
      total_records: 100,
      success_count: 95,
      failure_count: 5,
      accuracy_percentage: 94.8,
      average_latency_ms: 512,
      model: 'Google Cloud Vision + Tesseract Fallback',
    },
    metadata: {
      pipeline: 'Cloud Vision API -> Geometric Line Reassembly',
    },
    records_count: 100,
    size_kb: 3.2,
  },
];

describe('Phase 6: Telemetry and Analytics (BottomRibbon & RunDetailDrawer)', () => {
  it('renders category breakdown with formatted currency and percentage shares', () => {
    render(
      <BottomRibbon
        categories={sampleCategories}
        trends={sampleTrends}
        runs={sampleRuns}
        isMockMode={false}
      />
    );

    expect(screen.getByText(/Category Spend Breakdown/i)).toBeInTheDocument();
    expect(screen.getAllByText('Groceries & Food').length).toBeGreaterThanOrEqual(1);
    expect(screen.getByText('48.0%')).toBeInTheDocument();
    expect(screen.getByText('PKR 88,400.00')).toBeInTheDocument();
    expect(screen.getAllByText('Household & Cleaning').length).toBeGreaterThanOrEqual(1);
    expect(screen.getByText('17.4%')).toBeInTheDocument();
  });

  it('drills down into category details on click and returns back to all categories', () => {
    render(
      <BottomRibbon
        categories={sampleCategories}
        trends={sampleTrends}
        runs={sampleRuns}
        isMockMode={false}
      />
    );

    // Click on Groceries & Food
    const groceryRow = screen.getAllByText('Groceries & Food')[0];
    fireEvent.click(groceryRow);

    // Should reveal drill-down card with details
    expect(screen.getByText('TOTAL SPEND')).toBeInTheDocument();
    expect(screen.getByText('SHARE OF SPEND')).toBeInTheDocument();
    expect(screen.getByText('INGESTED ITEMS')).toBeInTheDocument();
    expect(screen.getByText('210 items')).toBeInTheDocument();
    expect(screen.getByText('AVG ITEM PRICE')).toBeInTheDocument();
    expect(screen.getByText('Staples, dairy, flour, produce, and fresh meat')).toBeInTheDocument();

    // Click Back to All Categories
    const backBtn = screen.getByText('Back to All Categories');
    fireEvent.click(backBtn);

    // Should return to normal view
    expect(screen.queryByText('Back to All Categories')).not.toBeInTheDocument();
  });

  it('renders spend trajectory velocity metrics and handles horizon toggle', () => {
    const onTrendMonthsChange = vi.fn();
    render(
      <BottomRibbon
        categories={sampleCategories}
        trends={sampleTrends}
        runs={sampleRuns}
        trendMonths={6}
        onTrendMonthsChange={onTrendMonthsChange}
        isMockMode={false}
      />
    );

    expect(screen.getByText(/Monthly Spend Trajectory/i)).toBeInTheDocument();
    expect(screen.getByText('Peak:')).toBeInTheDocument();
    expect(screen.getByText('PKR 184,250.00')).toBeInTheDocument();

    // Click 3M toggle
    const threeMBtn = screen.getByText('3M');
    fireEvent.click(threeMBtn);
    expect(onTrendMonthsChange).toHaveBeenCalledWith(3);
  });

  it('renders observability run logs table with accuracy badge and latency', () => {
    render(
      <BottomRibbon
        categories={sampleCategories}
        trends={sampleTrends}
        runs={sampleRuns}
        isMockMode={false}
      />
    );

    expect(screen.getByText(/Observability Run Logs/i)).toBeInTheDocument();
    expect(screen.getByText('gemini_flash_lite_evaluation_run')).toBeInTheDocument();
    expect(screen.getByText('96.2%')).toBeInTheDocument();
    expect(screen.getByText('385ms')).toBeInTheDocument();
    expect(screen.getByText('cloud_vision_hybrid_benchmark')).toBeInTheDocument();
    expect(screen.getByText('94.8%')).toBeInTheDocument();
    expect(screen.getByText('512ms')).toBeInTheDocument();
  });

  it('opens RunDetailDrawer when a run row is clicked and closes on Escape', () => {
    render(
      <BottomRibbon
        categories={sampleCategories}
        trends={sampleTrends}
        runs={sampleRuns}
        isMockMode={false}
      />
    );

    // Click on the gemini run row
    const runRow = screen.getByText('gemini_flash_lite_evaluation_run');
    fireEvent.click(runRow);

    // Drawer should open
    expect(screen.getByRole('dialog', { name: /run log inspector/i })).toBeInTheDocument();
    expect(screen.getByText('RUN IDENTIFIER')).toBeInTheDocument();
    expect(screen.getByText('fd26320d-116d-4c06-b111-089f581c444d')).toBeInTheDocument();
    expect(screen.getByText('TARGET MET')).toBeInTheDocument();
    expect(screen.getByText('PIPELINE EXECUTION ARCHITECTURE')).toBeInTheDocument();
    expect(screen.getAllByText(/OpenCV Deskew -> Perceptual Hash -> Gemini Vision/).length).toBeGreaterThanOrEqual(1);

    // Close via Close button
    const closeBtn = screen.getByLabelText('Close Inspector');
    fireEvent.click(closeBtn);
    expect(screen.queryByRole('dialog', { name: /run log inspector/i })).not.toBeInTheDocument();
  });

  it('prominently displays offline mock labels when isMockMode is true and never presents mock data as live', () => {
    const onExportCsv = vi.fn();
    render(
      <BottomRibbon
        categories={sampleCategories}
        trends={sampleTrends}
        runs={sampleRuns}
        isMockMode={true}
        onExportCsv={onExportCsv}
      />
    );

    // Mock Banner
    expect(screen.getByText('OFFLINE DEMO ANALYTICS (MOCK FIXTURE)')).toBeInTheDocument();
    expect(screen.getByText(/Not live telemetry/)).toBeInTheDocument();

    // Card Badges
    const mockBadges = screen.getAllByText('MOCK');
    expect(mockBadges.length).toBeGreaterThanOrEqual(3);

    // Export Mock CSV action
    const exportBtn = screen.getByText('Export Mock CSV');
    expect(exportBtn).toBeInTheDocument();
    fireEvent.click(exportBtn);
    expect(onExportCsv).toHaveBeenCalled();
  });

  it('handles loading skeletons without gradients or blur', () => {
    const { container } = render(
      <BottomRibbon
        categories={[]}
        trends={[]}
        runs={[]}
        isLoadingOverview={true}
        isLoadingTrends={true}
        isLoadingRuns={true}
      />
    );

    expect(screen.getByText('Loading run telemetry...')).toBeInTheDocument();
    expect(container.innerHTML).not.toContain('gradient');
    expect(container.innerHTML).not.toContain('backdrop-filter');
  });

  it('handles empty data states gracefully', () => {
    render(
      <BottomRibbon
        categories={[]}
        trends={[]}
        runs={[]}
        isLoadingOverview={false}
        isLoadingTrends={false}
        isLoadingRuns={false}
      />
    );

    expect(screen.getByText('No category spend recorded')).toBeInTheDocument();
    expect(screen.getByText('No historical trend data')).toBeInTheDocument();
    expect(screen.getByText('No evaluation run logs recorded under backend/logs/runs/')).toBeInTheDocument();
  });

  it('handles error and backend unavailable states with retry buttons', () => {
    const onRetryOverview = vi.fn();
    const onRetryTrends = vi.fn();
    const onRetryRuns = vi.fn();
    const onSwitchToMockMode = vi.fn();

    render(
      <BottomRibbon
        categories={[]}
        trends={[]}
        runs={[]}
        isErrorOverview={true}
        isErrorTrends={true}
        isErrorRuns={true}
        onRetryOverview={onRetryOverview}
        onRetryTrends={onRetryTrends}
        onRetryRuns={onRetryRuns}
        onSwitchToMockMode={onSwitchToMockMode}
        isMockMode={false}
      />
    );

    expect(screen.getByText('Failed to load category breakdown')).toBeInTheDocument();
    expect(screen.getByText('Failed to load trend velocity')).toBeInTheDocument();
    expect(screen.getByText(/Failed to load runs/)).toBeInTheDocument();

    // Click retry overview
    const retryButtons = screen.getAllByText(/Retry/i);
    fireEvent.click(retryButtons[0]);
    expect(onRetryOverview).toHaveBeenCalled();

    // Click Offline Mode button
    const offlineBtn = screen.getByText('Offline Mode');
    fireEvent.click(offlineBtn);
    expect(onSwitchToMockMode).toHaveBeenCalled();
  });
});
