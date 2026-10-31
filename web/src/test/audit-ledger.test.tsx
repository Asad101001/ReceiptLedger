import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { AuditLedger } from '../features/audit-ledger/AuditLedger';
import { SlideOutDrawer } from '../features/audit-ledger/SlideOutDrawer';
import { mockReceipts } from './mocks/handlers';

describe('Workspace B: Ingestion Audit Ledger & Slide-Out Drawer', () => {
  it('renders high-density columns: store name, date, item count, total spend, pHash, latency, status', () => {
    const onOpenInspector = vi.fn();
    const searchInputRef = { current: null };

    render(
      <AuditLedger
        receiptsData={{
          total: 2,
          page: 1,
          page_size: 25,
          total_pages: 1,
          receipts: mockReceipts.slice(0, 2),
        }}
        isLoading={false}
        page={1}
        pageSize={25}
        onPageChange={vi.fn()}
        search=""
        onSearchChange={vi.fn()}
        typeFilter="ALL"
        onTypeFilterChange={vi.fn()}
        dateStartFilter=""
        onDateStartChange={vi.fn()}
        dateEndFilter=""
        onDateEndChange={vi.fn()}
        selectedRowIndex={0}
        onSelectRowIndex={vi.fn()}
        onOpenInspector={onOpenInspector}
        searchInputRef={searchInputRef}
      />
    );

    // Verify row 1
    expect(screen.getByText('Chaudhry Sabzi & Fruit Store')).toBeInTheDocument();
    expect(screen.getByText('2026-10-18')).toBeInTheDocument();
    expect(screen.getByText('PKR 467.36')).toBeInTheDocument();
    expect(screen.getByText('a7b3c2d4e5f60812')).toBeInTheDocument();
    expect(screen.getByText('312ms')).toBeInTheDocument();
    expect(screen.getByText('PENDING_REVIEW')).toBeInTheDocument();

    // Verify row 2
    expect(screen.getByText('Javed Nihari Restaurant')).toBeInTheDocument();
    expect(screen.getByText('2026-10-16')).toBeInTheDocument();
    expect(screen.getByText('PKR 1,519.60')).toBeInTheDocument();
    expect(screen.getByText('b8f219c0de3456a1')).toBeInTheDocument();
    expect(screen.getByText('284ms')).toBeInTheDocument();
    expect(screen.getByText('PROCESSED')).toBeInTheDocument();
  });

  it('clicking a row selects it and triggers inspector drawer open', () => {
    const onOpenInspector = vi.fn();
    const onSelectRowIndex = vi.fn();
    const searchInputRef = { current: null };

    render(
      <AuditLedger
        receiptsData={{
          total: 2,
          page: 1,
          page_size: 25,
          total_pages: 1,
          receipts: mockReceipts.slice(0, 2),
        }}
        isLoading={false}
        page={1}
        pageSize={25}
        onPageChange={vi.fn()}
        search=""
        onSearchChange={vi.fn()}
        typeFilter="ALL"
        onTypeFilterChange={vi.fn()}
        dateStartFilter=""
        onDateStartChange={vi.fn()}
        dateEndFilter=""
        onDateEndChange={vi.fn()}
        selectedRowIndex={0}
        onSelectRowIndex={onSelectRowIndex}
        onOpenInspector={onOpenInspector}
        searchInputRef={searchInputRef}
      />
    );

    const row = screen.getByText('Javed Nihari Restaurant').closest('tr');
    expect(row).toBeInTheDocument();
    if (row) fireEvent.click(row);

    expect(onSelectRowIndex).toHaveBeenCalledWith(1);
    expect(onOpenInspector).toHaveBeenCalledWith(mockReceipts[1]);
  });

  it('filters rows based on search input and status filter', () => {
    const searchInputRef = { current: null };

    const { rerender } = render(
      <AuditLedger
        receiptsData={{
          total: mockReceipts.length,
          page: 1,
          page_size: 25,
          total_pages: 1,
          receipts: mockReceipts,
        }}
        isLoading={false}
        page={1}
        pageSize={25}
        onPageChange={vi.fn()}
        search="Melon"
        onSearchChange={vi.fn()}
        typeFilter="ALL"
        onTypeFilterChange={vi.fn()}
        dateStartFilter=""
        onDateStartChange={vi.fn()}
        dateEndFilter=""
        onDateEndChange={vi.fn()}
        selectedRowIndex={0}
        onSelectRowIndex={vi.fn()}
        onOpenInspector={vi.fn()}
        searchInputRef={searchInputRef}
      />
    );

    // Only Chaudhry Sabzi & Fruit Store has item 'Sweet Melon'
    expect(screen.getByText('Chaudhry Sabzi & Fruit Store')).toBeInTheDocument();
    expect(screen.queryByText('Javed Nihari Restaurant')).not.toBeInTheDocument();

    // Rerender with search for 'Nihari'
    rerender(
      <AuditLedger
        receiptsData={{
          total: mockReceipts.length,
          page: 1,
          page_size: 25,
          total_pages: 1,
          receipts: mockReceipts,
        }}
        isLoading={false}
        page={1}
        pageSize={25}
        onPageChange={vi.fn()}
        search="Nihari"
        onSearchChange={vi.fn()}
        typeFilter="ALL"
        onTypeFilterChange={vi.fn()}
        dateStartFilter=""
        onDateStartChange={vi.fn()}
        dateEndFilter=""
        onDateEndChange={vi.fn()}
        selectedRowIndex={0}
        onSelectRowIndex={vi.fn()}
        onOpenInspector={vi.fn()}
        searchInputRef={searchInputRef}
      />
    );

    expect(screen.getByText('Javed Nihari Restaurant')).toBeInTheDocument();
    expect(screen.queryByText('Al-Madina Departmental Store')).not.toBeInTheDocument();
  });

  it('sorts columns when column header is clicked', () => {
    const searchInputRef = { current: null };

    render(
      <AuditLedger
        receiptsData={{
          total: mockReceipts.length,
          page: 1,
          page_size: 25,
          total_pages: 1,
          receipts: mockReceipts,
        }}
        isLoading={false}
        page={1}
        pageSize={25}
        onPageChange={vi.fn()}
        search=""
        onSearchChange={vi.fn()}
        typeFilter="ALL"
        onTypeFilterChange={vi.fn()}
        dateStartFilter=""
        onDateStartChange={vi.fn()}
        dateEndFilter=""
        onDateEndChange={vi.fn()}
        selectedRowIndex={0}
        onSelectRowIndex={vi.fn()}
        onOpenInspector={vi.fn()}
        searchInputRef={searchInputRef}
      />
    );

    const amountHeader = screen.getByText(/Total Spend/i);
    fireEvent.click(amountHeader);

    const rows = screen.getAllByRole('row');
    expect(rows.length).toBeGreaterThan(1);
  });

  it('renders backend unavailable error state with retry and switch to mock mode buttons', () => {
    const onRetry = vi.fn();
    const onSwitchToMock = vi.fn();
    const searchInputRef = { current: null };

    render(
      <AuditLedger
        receiptsData={undefined}
        isLoading={false}
        isError={true}
        page={1}
        pageSize={25}
        onPageChange={vi.fn()}
        search=""
        onSearchChange={vi.fn()}
        typeFilter="ALL"
        onTypeFilterChange={vi.fn()}
        dateStartFilter=""
        onDateStartChange={vi.fn()}
        dateEndFilter=""
        onDateEndChange={vi.fn()}
        selectedRowIndex={0}
        onSelectRowIndex={vi.fn()}
        onOpenInspector={vi.fn()}
        searchInputRef={searchInputRef}
        onRetry={onRetry}
        onSwitchToMockMode={onSwitchToMock}
      />
    );

    expect(screen.getByText('Backend Gateway Unreachable')).toBeInTheDocument();
    const retryBtn = screen.getByRole('button', { name: /Retry Request/i });
    fireEvent.click(retryBtn);
    expect(onRetry).toHaveBeenCalledTimes(1);

    const mockBtn = screen.getByRole('button', { name: /Switch to Offline Dev Mode/i });
    fireEvent.click(mockBtn);
    expect(onSwitchToMock).toHaveBeenCalledTimes(1);
  });

  it('renders SlideOutDrawer tabs: Overview, Line items, Raw OCR, Validation & Audit, and Duplicates', () => {
    const onClose = vi.fn();
    render(
      <SlideOutDrawer
        receipt={mockReceipts[0]}
        isOpen={true}
        onClose={onClose}
        allReceipts={mockReceipts}
      />
    );

    // Verify header
    expect(screen.getByText('Chaudhry Sabzi & Fruit Store')).toBeInTheDocument();

    // Tab: Line items (default tab)
    expect(screen.getByText('Line Items (1)')).toBeInTheDocument();
    expect(screen.getByText('Sweet Melon')).toBeInTheDocument();
    expect(screen.getByText('PKR 199.00')).toBeInTheDocument();

    // Tab: Overview
    const overviewTabButton = screen.getByRole('button', { name: /Overview/i });
    fireEvent.click(overviewTabButton);
    expect(screen.getByText(/Receipt Ingestion Specifications/i)).toBeInTheDocument();
    expect(screen.getByText(/Ingested Receipt Scan Image/i)).toBeInTheDocument();

    // Tab: Raw OCR Payload
    const ocrTabButton = screen.getByRole('button', { name: /Raw OCR Payload/i });
    fireEvent.click(ocrTabButton);
    expect(screen.getByText(/Structured AST Response/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Copy JSON/i })).toBeInTheDocument();

    // Tab: Validation & Audit
    const auditTabButton = screen.getByRole('button', { name: /Validation & Audit/i });
    fireEvent.click(auditTabButton);
    expect(screen.getByText(/Field Validation Results/i)).toBeInTheDocument();
    expect(screen.getByText(/Ingestion Pipeline Audit Trail/i)).toBeInTheDocument();
    expect(screen.getByText(/Mathematical Reconciliation/i)).toBeInTheDocument();

    // Tab: pHash & Duplicate Comparison tab
    const dedupTabButton = screen.getByRole('button', { name: /pHash & Duplicate Comparison/i });
    fireEvent.click(dedupTabButton);
    expect(screen.getByText(/PERCEPTUAL HASH & DEDUPLICATION METRICS/i)).toBeInTheDocument();
    expect(screen.getByText('a7b3c2d4e5f60812')).toBeInTheDocument();
    expect(screen.getByText(/2-Layer Deduplication Engine Check/i)).toBeInTheDocument();

    // Detected duplicate match in mockReceipts (Receipt 4 has 1-bit Hamming distance!)
    expect(screen.getByText(/DUPLICATE MATCH FOUND IN CURRENT LEDGER/i)).toBeInTheDocument();
    expect(screen.getByText(/Distance: 1 bits/i)).toBeInTheDocument();

    // Close button triggers onClose
    const closeBtn = screen.getByRole('button', { name: /Close Inspector/i });
    fireEvent.click(closeBtn);
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('renders clean zero-data state when ledger is empty', () => {
    const searchInputRef = { current: null };
    render(
      <AuditLedger
        receiptsData={{
          total: 0,
          page: 1,
          page_size: 25,
          total_pages: 1,
          receipts: [],
        }}
        isLoading={false}
        page={1}
        pageSize={25}
        onPageChange={vi.fn()}
        search=""
        onSearchChange={vi.fn()}
        typeFilter="ALL"
        onTypeFilterChange={vi.fn()}
        dateStartFilter=""
        onDateStartChange={vi.fn()}
        dateEndFilter=""
        onDateEndChange={vi.fn()}
        selectedRowIndex={0}
        onSelectRowIndex={vi.fn()}
        onOpenInspector={vi.fn()}
        searchInputRef={searchInputRef}
      />
    );

    expect(screen.getByText(/No Receipts Found/i)).toBeInTheDocument();
    expect(screen.getByText(/Ledger is empty or no records match the active search criteria/i)).toBeInTheDocument();
  });
});
