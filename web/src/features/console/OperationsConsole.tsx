import React, { useState, useRef, useCallback } from 'react';
import clsx from 'clsx';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api, getApiBaseUrl } from '../../api/client';
import { useConsoleStore } from '../../store/useConsoleStore';
import { useHotkeys } from '../../hooks/useHotkeys';
import { AppLayout } from '../../components/layout/AppLayout';
import { TopStatusBar } from '../status/TopStatusBar';
import { KpiMetricsRow } from '../kpi/KpiMetricsRow';
import { ReviewDesk } from '../review-desk/ReviewDesk';
import { AuditLedger } from '../audit-ledger/AuditLedger';
import { SlideOutDrawer } from '../audit-ledger/SlideOutDrawer';
import { BottomRibbon } from '../telemetry/BottomRibbon';
import { KeyboardShortcutsPanel } from '../../components/KeyboardShortcutsPanel';
import { UploadReceiptDrawer } from '../../components/UploadReceiptDrawer';
import { DuplicateConflictBanner } from '../../components/DuplicateConflictBanner';
import { NetworkErrorBanner } from '../../components/NetworkErrorBanner';
import {
  ReviewQueueItem,
  ReviewQueueResolveRequest,
} from '../../types';
import {
  mockHealthResponse,
  mockOverviewResponse,
  mockReviewQueue,
  mockReceipts,
  mockTrends,
  mockSystemRuns,
} from '../../lib/mockData';

interface OperationsConsoleProps {
  userEmail?: string;
  onLogout: () => void;
  isMockMode?: boolean;
  onEnterDevMockMode?: () => void;
}

export const OperationsConsole: React.FC<OperationsConsoleProps> = ({
  userEmail,
  onLogout,
  isMockMode = false,
  onEnterDevMockMode,
}) => {
  const queryClient = useQueryClient();
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Store state
  const {
    activeNav,
    setActiveNav,
    activeQueueIndex,
    setActiveQueueIndex,
    nextQueueItem,
    selectedReceiptRowIndex,
    setSelectedReceiptRowIndex,
    ledgerSearch,
    setLedgerSearch,
    typeFilter,
    setTypeFilter,
    dateStartFilter,
    setDateStartFilter,
    dateEndFilter,
    setDateEndFilter,
    inspectedReceipt,
    isDrawerOpen,
    openInspector,
    closeInspector,
    isShortcutsPanelOpen,
    toggleShortcutsPanel,
    closeShortcutsPanel,
    isUploadDrawerOpen,
    closeUploadDrawer,
    selectedYear,
    selectedMonth,
  } = useConsoleStore();

  const [ledgerPage, setLedgerPage] = useState<number>(1);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [trendMonths, setTrendMonths] = useState<number>(6);

  // ── Queries ─────────────────────────────────────────────────────────────────

  const healthQuery = useQuery({
    queryKey: ['health'],
    queryFn: () => api.getHealth(),
    refetchInterval: isMockMode ? false : 30000,
    enabled: !isMockMode,
  });

  const overviewQuery = useQuery({
    queryKey: ['overview', selectedYear, selectedMonth],
    queryFn: () => api.getDashboardOverview(selectedYear, selectedMonth),
    enabled: !isMockMode,
  });

  const reviewQueueQuery = useQuery({
    queryKey: ['reviewQueue', 'UNRESOLVED'],
    queryFn: () => api.getReviewQueue('UNRESOLVED'),
    enabled: !isMockMode,
  });

  const receiptsQuery = useQuery({
    queryKey: ['receipts', ledgerPage, 25, ledgerSearch],
    queryFn: () => api.getReceipts({ page: ledgerPage, pageSize: 25, search: ledgerSearch }),
    enabled: !isMockMode,
  });

  const trendsQuery = useQuery({
    queryKey: ['trends', trendMonths],
    queryFn: () => api.getTrends(trendMonths),
    enabled: !isMockMode,
  });

  const runsQuery = useQuery({
    queryKey: ['systemRuns', 20],
    queryFn: () => api.getSystemRuns(20),
    enabled: !isMockMode,
  });

  // Mock Queue state for reliable Offline Dev Mode visual triage
  const [mockQueue, setMockQueue] = useState<ReviewQueueItem[]>(() => [...mockReviewQueue]);

  const handleReloadMockQueue = useCallback(() => {
    setMockQueue([...mockReviewQueue]);
    setActiveQueueIndex(0);
  }, [setActiveQueueIndex]);

  const handleSwitchToMockMode = useCallback(() => {
    setMockQueue([...mockReviewQueue]);
    setActiveQueueIndex(0);
    if (onEnterDevMockMode) {
      onEnterDevMockMode();
    }
  }, [setActiveQueueIndex, onEnterDevMockMode]);

  const queueItems = isMockMode ? mockQueue : (reviewQueueQuery.data || []);
  const receiptsList = isMockMode
    ? (receiptsQuery.data?.receipts || mockReceipts)
    : (receiptsQuery.data?.receipts || []);
  const receiptsData = isMockMode
    ? (receiptsQuery.data || {
        receipts: mockReceipts,
        total: mockReceipts.length,
        page: 1,
        page_size: 25,
        total_pages: 1,
      })
    : receiptsQuery.data;
  const healthData = isMockMode
    ? (healthQuery.data || mockHealthResponse)
    : healthQuery.data;
  const baseOverview = overviewQuery.data || mockOverviewResponse;
  const overviewData = isMockMode
    ? {
        ...baseOverview,
        pending_review_count: queueItems.length,
        stat_cards: baseOverview.stat_cards?.map((card) =>
          card.key === 'pending_reviews'
            ? {
                ...card,
                value: queueItems.length,
                formatted_value: `${queueItems.length} Pending`,
              }
            : card
        ),
      }
    : overviewQuery.data;
  const trendsData = isMockMode
    ? { months: mockTrends.months.slice(-trendMonths) }
    : trendsQuery.data;
  const runsData = isMockMode
    ? (runsQuery.data || mockSystemRuns)
    : runsQuery.data;

  const handleExportCsv = useCallback(() => {
    if (isMockMode) {
      const headers = [
        'receipt_id',
        'receipt_date',
        'merchant_name',
        'receipt_type',
        'status',
        'item_name',
        'quantity',
        'unit',
        'unit_price',
        'total_price',
        'category',
        'confidence_score',
        'is_verified',
      ];
      const rows: string[] = [headers.join(',')];
      receiptsList.forEach((r) => {
        if (r.line_items && r.line_items.length > 0) {
          r.line_items.forEach((item) => {
            rows.push(
              [
                `"${r.id}"`,
                `"${r.receipt_date || ''}"`,
                `"${(r.merchant_name || '').replace(/"/g, '""')}"`,
                `"${r.receipt_type || 'PRINTED'}"`,
                `"${r.status}"`,
                `"${(item.item_name || '').replace(/"/g, '""')}"`,
                item.quantity,
                `"${item.unit}"`,
                item.unit_price,
                item.total_price,
                `"${item.category_name || 'Groceries & Food'}"`,
                item.confidence_score,
                item.is_verified,
              ].join(',')
            );
          });
        } else {
          rows.push(
            [
              `"${r.id}"`,
              `"${r.receipt_date || ''}"`,
              `"${(r.merchant_name || '').replace(/"/g, '""')}"`,
              `"${r.receipt_type || 'PRINTED'}"`,
              `"${r.status}"`,
              '""',
              1,
              '""',
              r.total_amount,
              r.total_amount,
              '""',
              r.ocr_confidence || 1.0,
              true,
            ].join(',')
          );
        }
      });
      const blob = new Blob([rows.join('\n')], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute(
        'download',
        `receiptledger_mock_export_${selectedYear}-${String(selectedMonth).padStart(2, '0')}.csv`
      );
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      return;
    }

    const url = api.getExportCsvUrl(selectedYear, selectedMonth);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute(
      'download',
      `receiptledger_export_${selectedYear}-${String(selectedMonth).padStart(2, '0')}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }, [isMockMode, receiptsList, selectedYear, selectedMonth]);

  // Keep active queue index within bounds
  const safeActiveQueueIndex = Math.min(
    Math.max(0, queueItems.length - 1),
    activeQueueIndex
  );

  // ── Optimistic Review Resolution Mutation ───────────────────────────────────

  const resolveMutation = useMutation({
    mutationFn: async ({
      queueId,
      payload,
    }: {
      queueId: string;
      payload: ReviewQueueResolveRequest;
    }) => {
      return api.resolveReviewItem(queueId, payload);
    },
    onMutate: async ({ queueId }) => {
      // Cancel outgoing queries
      await queryClient.cancelQueries({ queryKey: ['reviewQueue', 'UNRESOLVED'] });
      const previousQueue = queryClient.getQueryData<ReviewQueueItem[]>([
        'reviewQueue',
        'UNRESOLVED',
      ]);

      // Optimistic update: remove resolved item
      if (previousQueue) {
        queryClient.setQueryData<ReviewQueueItem[]>(
          ['reviewQueue', 'UNRESOLVED'],
          previousQueue.filter((item) => (item.queue_id || item.id) !== queueId)
        );
      }

      // Auto-advance
      nextQueueItem(queueItems.length);

      return { previousQueue };
    },
    onError: (err, _, context) => {
      // Rollback on error
      if (context?.previousQueue) {
        queryClient.setQueryData(['reviewQueue', 'UNRESOLVED'], context.previousQueue);
      }
      setErrorMessage(err instanceof Error ? err.message : 'Failed to resolve item.');
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['overview'] });
      queryClient.invalidateQueries({ queryKey: ['reviewQueue'] });
      queryClient.invalidateQueries({ queryKey: ['receipts'] });
    },
  });

  const handleResolveItem = useCallback(
    async (queueId: string, payload: ReviewQueueResolveRequest) => {
      if (isMockMode) {
        setMockQueue((prev) => {
          const next = prev.filter((item) => (item.queue_id || item.id) !== queueId);
          setActiveQueueIndex(Math.min(Math.max(0, next.length - 1), activeQueueIndex));
          return next;
        });
        return;
      }
      await resolveMutation.mutateAsync({ queueId, payload });
    },
    [isMockMode, activeQueueIndex, setActiveQueueIndex, resolveMutation]
  );

  // ── Seed & Reset Handlers ───────────────────────────────────────────────────

  const seedMutation = useMutation({
    mutationFn: () => api.seedDemoData(),
    onSuccess: () => {
      setErrorMessage(null);
      queryClient.invalidateQueries();
    },
    onError: (err) => {
      setErrorMessage(err instanceof Error ? err.message : 'Failed to seed demo data.');
    },
  });

  const resetMutation = useMutation({
    mutationFn: () => api.resetLedger(),
    onSuccess: () => {
      setErrorMessage(null);
      setActiveQueueIndex(0);
      setSelectedReceiptRowIndex(0);
      queryClient.invalidateQueries();
    },
    onError: (err) => {
      setErrorMessage(err instanceof Error ? err.message : 'Failed to reset ledger.');
    },
  });

  // ── Hotkey Handlers ─────────────────────────────────────────────────────────

  const handleApproveActiveItem = useCallback(() => {
    if (queueItems.length > 0) {
      const activeItem = queueItems[safeActiveQueueIndex];
      if (activeItem) {
        const queueId = activeItem.queue_id || activeItem.id;
        handleResolveItem(queueId, {
          confirmed_name: activeItem.candidate_name || 'Accepted Product',
          action: 'ACCEPTED',
        });
      }
    }
  }, [queueItems, safeActiveQueueIndex, handleResolveItem]);

  const handleSaveEditsActive = useCallback(() => {
    if (queueItems.length > 0) {
      const activeItem = queueItems[safeActiveQueueIndex];
      if (activeItem) {
        const queueId = activeItem.queue_id || activeItem.id;
        const li = activeItem.line_item;
        handleResolveItem(queueId, {
          confirmed_name: activeItem.candidate_name || 'Corrected Product',
          confirmed_quantity: li?.quantity ?? 1,
          confirmed_unit: li?.unit ?? 'pcs',
          confirmed_unit_price: li?.unit_price ?? 0,
          confirmed_total_price: li?.total_price ?? 0,
          action: 'EDITED',
        });
      }
    }
  }, [queueItems, safeActiveQueueIndex, handleResolveItem]);

  const handleSelectPrevRow = useCallback(() => {
    setSelectedReceiptRowIndex(Math.max(0, selectedReceiptRowIndex - 1));
  }, [selectedReceiptRowIndex, setSelectedReceiptRowIndex]);

  const handleSelectNextRow = useCallback(() => {
    setSelectedReceiptRowIndex(
      Math.min(Math.max(0, receiptsList.length - 1), selectedReceiptRowIndex + 1)
    );
  }, [selectedReceiptRowIndex, receiptsList.length, setSelectedReceiptRowIndex]);

  const handleOpenInspectorSelected = useCallback(() => {
    if (receiptsList.length > 0 && receiptsList[selectedReceiptRowIndex]) {
      openInspector(receiptsList[selectedReceiptRowIndex]);
    }
  }, [receiptsList, selectedReceiptRowIndex, openInspector]);

  const handleFocusSearch = useCallback(() => {
    if (searchInputRef.current) {
      searchInputRef.current.focus();
      searchInputRef.current.select();
    }
  }, []);

  const handleCloseActiveDrawer = useCallback(() => {
    if (isDrawerOpen) {
      closeInspector();
    } else if (isShortcutsPanelOpen) {
      closeShortcutsPanel();
    }
  }, [isDrawerOpen, isShortcutsPanelOpen, closeInspector, closeShortcutsPanel]);

  useHotkeys({
    onApproveActiveItem: handleApproveActiveItem,
    onSaveEdits: handleSaveEditsActive,
    onSelectPrevRow: handleSelectPrevRow,
    onSelectNextRow: handleSelectNextRow,
    onOpenInspector: handleOpenInspectorSelected,
    onCloseDrawer: handleCloseActiveDrawer,
    onFocusSearch: handleFocusSearch,
    onToggleShortcuts: toggleShortcutsPanel,
  });

  const handleViewMatchedReceipt = (receiptId: string) => {
    const matched = receiptsList.find((r) => r.id === receiptId);
    if (matched) {
      openInspector(matched);
    } else {
      // Create minimal receipt object to inspect image
      openInspector({
        id: receiptId,
        merchant_name: 'Matched Duplicate Receipt',
        receipt_date: '2026-10-18',
        total_amount: 0,
        status: 'DUPLICATE',
        line_items: [],
      });
    }
  };

  const hasNetworkError =
    !isMockMode &&
    (overviewQuery.isError ||
      reviewQueueQuery.isError ||
      receiptsQuery.isError);

  return (
    <AppLayout
      userEmail={userEmail}
      onLogout={onLogout}
      pendingReviewCount={queueItems.length}
    >
      {/* ── 1. Top Status Bar & Gateway Controls ────────────────────────────── */}
      <TopStatusBar
        health={healthData}
        isHealthLoading={!isMockMode && healthQuery.isLoading}
        onSeedDemo={async () => {
          if (isMockMode) {
            handleReloadMockQueue();
            return;
          }
          await seedMutation.mutateAsync();
        }}
        onResetLedger={async () => {
          if (isMockMode) {
            setMockQueue([]);
            setActiveQueueIndex(0);
            return;
          }
          await resetMutation.mutateAsync();
        }}
        isSeeding={!isMockMode && seedMutation.isPending}
        isResetting={!isMockMode && resetMutation.isPending}
        userEmail={userEmail}
        onLogout={onLogout}
        isMockMode={isMockMode}
        onEnterDevMockMode={handleSwitchToMockMode}
        onExportCsv={handleExportCsv}
      />

      {/* ── Sub-Navigation Workspace Bar ───────────────────────────────────── */}
      <div className="bg-white border-b border-[#CBD5E1] px-3 sm:px-5 py-2 sm:py-2.5 flex items-center justify-between select-none overflow-x-auto scrollbar-none">
        <div className="flex items-center gap-1.5 sm:gap-2 shrink-0">
          <button
            onClick={() => setActiveNav('overview')}
            className={clsx(
              'px-3 py-1 text-xs font-mono font-semibold rounded-full border transition-colors',
              activeNav === 'overview'
                ? 'bg-black text-white border-black'
                : 'bg-[#F8FAFC] text-slate-700 border-[#CBD5E1] hover:bg-slate-100'
            )}
          >
            Overview Console
          </button>
          <button
            onClick={() => setActiveNav('review')}
            className={clsx(
              'px-3 py-1 text-xs font-mono font-semibold rounded-full border transition-colors flex items-center gap-1.5',
              activeNav === 'review'
                ? 'bg-black text-white border-black'
                : 'bg-[#F8FAFC] text-slate-700 border-[#CBD5E1] hover:bg-slate-100'
            )}
          >
            <span>Receipt Review</span>
            {queueItems.length > 0 && (
              <span
                className={clsx(
                  'text-[10px] px-1.5 py-0.5 rounded-full font-bold',
                  activeNav === 'review'
                    ? 'bg-amber-400 text-black'
                    : 'bg-amber-100 text-amber-900 border border-amber-300'
                )}
              >
                {queueItems.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveNav('ledger')}
            className={clsx(
              'px-3 py-1 text-xs font-mono font-semibold rounded-full border transition-colors',
              activeNav === 'ledger'
                ? 'bg-black text-white border-black'
                : 'bg-[#F8FAFC] text-slate-700 border-[#CBD5E1] hover:bg-slate-100'
            )}
          >
            Audit Ledger
          </button>
          <button
            onClick={() => setActiveNav('health')}
            className={clsx(
              'px-3 py-1 text-xs font-mono font-semibold rounded-full border transition-colors',
              activeNav === 'health'
                ? 'bg-black text-white border-black'
                : 'bg-[#F8FAFC] text-slate-700 border-[#CBD5E1] hover:bg-slate-100'
            )}
          >
            System Health &amp; Runs
          </button>
        </div>

        <div className="hidden lg:flex items-center gap-3 text-xs font-mono text-slate-500">
          <div className="flex items-center gap-1.5">
            <span>Search</span>
            <kbd className="text-[10px]">/</kbd>
          </div>
          <span>•</span>
          <div className="flex items-center gap-1.5">
            <span>Inspect</span>
            <kbd className="text-[10px]">Space</kbd>
          </div>
          <span>•</span>
          <div className="flex items-center gap-1.5">
            <span>Approve</span>
            <kbd className="text-[10px]">Enter</kbd>
          </div>
        </div>
      </div>

      {/* ── Main Operations Workspace ────────────────────────────────────────── */}
      <main className="flex-1 p-4 xl:p-5 max-w-[1920px] w-full mx-auto space-y-4">
        {/* Network Error Banner with Retry & Offline Dev Mode Switch */}
        {hasNetworkError && (
          <NetworkErrorBanner
            message="Gateway connection issue. Verify backend is running on http://localhost:8000."
            onRetry={() => {
              queryClient.invalidateQueries();
            }}
            isRetrying={overviewQuery.isFetching}
            onSwitchToMockMode={handleSwitchToMockMode}
          />
        )}

        {/* 409 Duplicate Conflict Banner */}
        <DuplicateConflictBanner onViewReceipt={handleViewMatchedReceipt} />

        {/* Generic Error Feedback */}
        {errorMessage && (
          <div className="bg-red-50 border border-red-300 text-red-900 text-xs font-mono p-3 rounded flex items-center justify-between">
            <span>{errorMessage}</span>
            <button
              onClick={() => setErrorMessage(null)}
              className="text-red-700 hover:text-red-900 text-xs font-bold uppercase"
            >
              Dismiss
            </button>
          </div>
        )}

        {/* ── 2. Top KPI Metrics Row (4 Cards) ───────────────────────────────── */}
        <KpiMetricsRow
          overview={overviewData}
          isLoading={!isMockMode && overviewQuery.isLoading}
          isMockMode={isMockMode}
        />

        {/* ── 3. Workspaces Layout Based on activeNav ─────────────────────────── */}
        {activeNav === 'overview' && (
          <>
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 items-stretch">
              {/* Workspace A: Human-in-the-Loop Review Desk */}
              <section className="min-h-[520px] xl:h-[580px]">
                <ReviewDesk
                  queueItems={queueItems}
                  activeIndex={safeActiveQueueIndex}
                  onSelectIndex={setActiveQueueIndex}
                  onResolveItem={handleResolveItem}
                  isResolving={!isMockMode && resolveMutation.isPending}
                  isMockMode={isMockMode}
                  onReloadMockQueue={handleReloadMockQueue}
                  onEnterDevMockMode={handleSwitchToMockMode}
                />
              </section>

              {/* Workspace B: Ingestion Audit Ledger */}
              <section className="min-h-[520px] xl:h-[580px]">
                <AuditLedger
                  receiptsData={receiptsData}
                  isLoading={!isMockMode && receiptsQuery.isLoading}
                  isError={!isMockMode && receiptsQuery.isError}
                  page={ledgerPage}
                  pageSize={25}
                  onPageChange={setLedgerPage}
                  search={ledgerSearch}
                  onSearchChange={(s) => {
                    setLedgerSearch(s);
                    setLedgerPage(1);
                  }}
                  typeFilter={typeFilter}
                  onTypeFilterChange={setTypeFilter}
                  dateStartFilter={dateStartFilter}
                  onDateStartChange={setDateStartFilter}
                  dateEndFilter={dateEndFilter}
                  onDateEndChange={setDateEndFilter}
                  selectedRowIndex={selectedReceiptRowIndex}
                  onSelectRowIndex={setSelectedReceiptRowIndex}
                  onOpenInspector={openInspector}
                  searchInputRef={searchInputRef}
                  onRetry={() => {
                    queryClient.invalidateQueries({ queryKey: ['receipts'] });
                  }}
                  onSwitchToMockMode={handleSwitchToMockMode}
                  isMockMode={isMockMode}
                />
              </section>
            </div>

            {/* ── 4. Bottom Telemetry & Analytics Ribbon ─────────────────────────── */}
            <section>
              <BottomRibbon
                categories={overviewData?.category_breakdown || []}
                trends={trendsData?.months || []}
                runs={runsData || []}
                isLoadingOverview={!isMockMode && overviewQuery.isLoading}
                isErrorOverview={!isMockMode && overviewQuery.isError}
                isLoadingTrends={!isMockMode && trendsQuery.isLoading}
                isErrorTrends={!isMockMode && trendsQuery.isError}
                isLoadingRuns={!isMockMode && runsQuery.isLoading}
                isErrorRuns={!isMockMode && runsQuery.isError}
                onRetryOverview={() => queryClient.invalidateQueries({ queryKey: ['overview'] })}
                onRetryTrends={() => queryClient.invalidateQueries({ queryKey: ['trends'] })}
                onRetryRuns={() => queryClient.invalidateQueries({ queryKey: ['systemRuns'] })}
                onSwitchToMockMode={handleSwitchToMockMode}
                trendMonths={trendMonths}
                onTrendMonthsChange={setTrendMonths}
                isMockMode={isMockMode}
                onExportCsv={handleExportCsv}
              />
            </section>
          </>
        )}

        {activeNav === 'review' && (
          <section className="min-h-[640px] xl:h-[680px]">
            <ReviewDesk
              queueItems={queueItems}
              activeIndex={safeActiveQueueIndex}
              onSelectIndex={setActiveQueueIndex}
              onResolveItem={handleResolveItem}
              isResolving={!isMockMode && resolveMutation.isPending}
              isMockMode={isMockMode}
              onReloadMockQueue={handleReloadMockQueue}
              onEnterDevMockMode={handleSwitchToMockMode}
            />
          </section>
        )}

        {activeNav === 'ledger' && (
          <section className="min-h-[640px] xl:h-[680px]">
            <AuditLedger
              receiptsData={receiptsData}
              isLoading={!isMockMode && receiptsQuery.isLoading}
              isError={!isMockMode && receiptsQuery.isError}
              page={ledgerPage}
              pageSize={25}
              onPageChange={setLedgerPage}
              search={ledgerSearch}
              onSearchChange={(s) => {
                setLedgerSearch(s);
                setLedgerPage(1);
              }}
              typeFilter={typeFilter}
              onTypeFilterChange={setTypeFilter}
              dateStartFilter={dateStartFilter}
              onDateStartChange={setDateStartFilter}
              dateEndFilter={dateEndFilter}
              onDateEndChange={setDateEndFilter}
              selectedRowIndex={selectedReceiptRowIndex}
              onSelectRowIndex={setSelectedReceiptRowIndex}
              onOpenInspector={openInspector}
              searchInputRef={searchInputRef}
              onRetry={() => {
                queryClient.invalidateQueries({ queryKey: ['receipts'] });
              }}
              onSwitchToMockMode={handleSwitchToMockMode}
              isMockMode={isMockMode}
            />
          </section>
        )}

        {activeNav === 'health' && (
          <div className="space-y-4">
            {/* System Engine Telemetry Strip */}
            <section className="bg-white border border-[#CBD5E1] rounded-xl p-4 select-none">
              <div className="flex items-center justify-between pb-3 border-b border-[#CBD5E1] mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></div>
                  <h2 className="font-mono font-bold text-xs uppercase tracking-wider text-slate-900">
                    GATEWAY SYSTEM ENGINE STATUS &amp; QUOTA TELEMETRY
                  </h2>
                </div>
                <div className="flex items-center gap-2">
                  {isMockMode && (
                    <span className="text-[10px] font-mono bg-amber-400 text-black px-2 py-0.5 rounded font-bold uppercase">
                      OFFLINE FIXTURE TELEMETRY
                    </span>
                  )}
                  <span className="text-[11px] font-mono text-slate-500 truncate max-w-[280px]">
                    Gateway: {getApiBaseUrl()}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3 font-mono text-xs">
                {/* 1. Gemini AI */}
                <div className="bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-lg">
                  <div className="flex items-center justify-between text-slate-500 text-[10px] font-bold uppercase">
                    <span>PRIMARY MODEL</span>
                    <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                  </div>
                  <div className="font-bold text-slate-900 text-sm mt-1 truncate">
                    Gemini Flash-Lite
                  </div>
                  <div className="text-[11px] text-slate-500 mt-1">
                    {healthData?.engines?.gemini || 'ok (model=gemini-3.5-flash-lite)'}
                  </div>
                </div>

                {/* 2. Google Cloud Vision */}
                <div className="bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-lg">
                  <div className="flex items-center justify-between text-slate-500 text-[10px] font-bold uppercase">
                    <span>CLOUD VISION</span>
                    <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                  </div>
                  <div className="font-bold text-slate-900 text-sm mt-1 truncate">
                    Quota Remaining
                  </div>
                  <div className="text-[11px] text-emerald-700 font-bold mt-1">
                    {healthData?.engines?.cloud_vision || 'ok (quota_remaining=950)'}
                  </div>
                </div>

                {/* 3. Database Persistence */}
                <div className="bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-lg">
                  <div className="flex items-center justify-between text-slate-500 text-[10px] font-bold uppercase">
                    <span>PERSISTENCE</span>
                    <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                  </div>
                  <div className="font-bold text-slate-900 text-sm mt-1 truncate">
                    Supabase PostgreSQL
                  </div>
                  <div className="text-[11px] text-slate-500 mt-1">
                    Engine: {healthData?.engines?.database || 'supabase'} (3NF Schema)
                  </div>
                </div>

                {/* 4. Local Tesseract 5 */}
                <div className="bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-lg">
                  <div className="flex items-center justify-between text-slate-500 text-[10px] font-bold uppercase">
                    <span>FALLBACK OCR</span>
                    <span className="w-2 h-2 rounded-full bg-slate-400"></span>
                  </div>
                  <div className="font-bold text-slate-900 text-sm mt-1 truncate">
                    Tesseract 5 CPU
                  </div>
                  <div className="text-[11px] text-slate-500 mt-1">
                    Mode: --psm 6 (Digit Whitelist)
                  </div>
                </div>

                {/* 5. EasyOCR CRNN */}
                <div className="bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-lg">
                  <div className="flex items-center justify-between text-slate-500 text-[10px] font-bold uppercase">
                    <span>HANDWRITING OCR</span>
                    <span className="w-2 h-2 rounded-full bg-slate-400"></span>
                  </div>
                  <div className="font-bold text-slate-900 text-sm mt-1 truncate">
                    EasyOCR PyTorch
                  </div>
                  <div className="text-[11px] text-slate-500 mt-1">
                    Status: {healthData?.engines?.easyocr || 'ok (lazy-loaded)'}
                  </div>
                </div>
              </div>
            </section>

            {/* Bottom Telemetry & Observability Hub */}
            <section>
              <BottomRibbon
                categories={overviewData?.category_breakdown || []}
                trends={trendsData?.months || []}
                runs={runsData || []}
                isLoadingOverview={!isMockMode && overviewQuery.isLoading}
                isErrorOverview={!isMockMode && overviewQuery.isError}
                isLoadingTrends={!isMockMode && trendsQuery.isLoading}
                isErrorTrends={!isMockMode && trendsQuery.isError}
                isLoadingRuns={!isMockMode && runsQuery.isLoading}
                isErrorRuns={!isMockMode && runsQuery.isError}
                onRetryOverview={() => queryClient.invalidateQueries({ queryKey: ['overview'] })}
                onRetryTrends={() => queryClient.invalidateQueries({ queryKey: ['trends'] })}
                onRetryRuns={() => queryClient.invalidateQueries({ queryKey: ['systemRuns'] })}
                onSwitchToMockMode={handleSwitchToMockMode}
                trendMonths={trendMonths}
                onTrendMonthsChange={setTrendMonths}
                isMockMode={isMockMode}
                onExportCsv={handleExportCsv}
              />
            </section>
          </div>
        )}
      </main>

      {/* ── Slide-Out Inspector Drawer ────────────────────────────────────────── */}
      <SlideOutDrawer
        receipt={inspectedReceipt}
        isOpen={isDrawerOpen}
        onClose={closeInspector}
        allReceipts={receiptsList}
      />

      {/* ── Keyboard Shortcuts Help Drawer / Panel (Inline, no modal) ───────── */}
      <KeyboardShortcutsPanel
        isOpen={isShortcutsPanelOpen}
        onClose={closeShortcutsPanel}
      />

      {/* ── Receipt Upload Drawer ────────────────────────────────────────────── */}
      <UploadReceiptDrawer
        isOpen={isUploadDrawerOpen}
        onClose={closeUploadDrawer}
        onUploadSuccess={() => {
          queryClient.invalidateQueries();
        }}
      />
    </AppLayout>
  );
};
