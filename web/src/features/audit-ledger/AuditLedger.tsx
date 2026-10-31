import React, { useState } from 'react';
import {
  Search,
  Download,
  Calendar,
  ChevronLeft,
  ChevronRight,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  RotateCcw,
  AlertCircle,
  WifiOff,
} from 'lucide-react';
import { PaginatedReceiptsResponse, ReceiptDetail } from '../../types';
import { api } from '../../api/client';
import { formatPKR, formatDate } from '../../lib/formatters';
import { ProjectIcon } from '../../components/ui/ProjectIcon';

export type ReceiptTypeFilter = 'ALL' | 'PRINTED' | 'HANDWRITTEN';
export type ReceiptStatusFilter = 'ALL' | 'PROCESSED' | 'PENDING_REVIEW' | 'FLAGGED' | 'DUPLICATE' | 'FAILED';
export type SortField = 'date' | 'merchant' | 'amount' | 'confidence' | 'items' | 'latency';
export type SortOrder = 'asc' | 'desc';

export interface AuditLedgerProps {
  receiptsData?: PaginatedReceiptsResponse;
  isLoading: boolean;
  isError?: boolean;
  page: number;
  pageSize: number;
  onPageChange: (newPage: number) => void;
  search: string;
  onSearchChange: (newSearch: string) => void;
  typeFilter: ReceiptTypeFilter;
  onTypeFilterChange: (filter: ReceiptTypeFilter) => void;
  dateStartFilter: string;
  onDateStartChange: (date: string) => void;
  dateEndFilter: string;
  onDateEndChange: (date: string) => void;
  selectedRowIndex: number;
  onSelectRowIndex: (index: number) => void;
  onOpenInspector: (receipt: ReceiptDetail) => void;
  searchInputRef: React.RefObject<HTMLInputElement>;
  onRetry?: () => void;
  onSwitchToMockMode?: () => void;
  isMockMode?: boolean;
}

export const AuditLedger: React.FC<AuditLedgerProps> = ({
  receiptsData,
  isLoading,
  isError = false,
  page,
  pageSize,
  onPageChange,
  search,
  onSearchChange,
  typeFilter,
  onTypeFilterChange,
  dateStartFilter,
  onDateStartChange,
  dateEndFilter,
  onDateEndChange,
  selectedRowIndex,
  onSelectRowIndex,
  onOpenInspector,
  searchInputRef,
  onRetry,
  onSwitchToMockMode,
  isMockMode = false,
}) => {
  const [statusFilter, setStatusFilter] = useState<ReceiptStatusFilter>('ALL');
  const [sortField, setSortField] = useState<SortField | null>(null);
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');

  const receipts = receiptsData?.receipts || [];
  const totalCount = receiptsData?.total || receipts.length;
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

  // Multi-column filtering using available supported record data
  const filteredReceipts = receipts.filter((r) => {
    // 1. Search filter across merchant, receipt ID, line items, and raw text
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      const matchMerchant = (r.merchant_name || '').toLowerCase().includes(q);
      const matchId = (r.id || '').toLowerCase().includes(q);
      const matchType = (r.receipt_type || '').toLowerCase().includes(q);
      const matchPhash = (r.phash_64 || '').toLowerCase().includes(q);
      const matchItems = r.line_items?.some(
        (li) =>
          (li.item_name || '').toLowerCase().includes(q) ||
          (li.raw_text || '').toLowerCase().includes(q)
      );
      if (!matchMerchant && !matchId && !matchType && !matchPhash && !matchItems) {
        return false;
      }
    }

    // 2. Receipt type filter (Printed / Handwritten / All)
    if (typeFilter !== 'ALL' && (r.receipt_type || 'PRINTED') !== typeFilter) {
      return false;
    }

    // 3. Status filter (Processed / Pending / Flagged / Duplicate / Failed / All)
    if (statusFilter !== 'ALL') {
      const currentStatus = r.status || 'PROCESSED';
      if (currentStatus !== statusFilter) {
        return false;
      }
    }

    // 4. Date range filters
    const rDate = r.receipt_date || '';
    if (dateStartFilter && rDate < dateStartFilter) {
      return false;
    }
    if (dateEndFilter && rDate > dateEndFilter) {
      return false;
    }

    return true;
  });

  // Client-side multi-column sorting (preserves server order when sortField is null)
  const sortedReceipts = sortField
    ? [...filteredReceipts].sort((a, b) => {
        let comparison = 0;
        if (sortField === 'date') {
          comparison = (a.receipt_date || '').localeCompare(b.receipt_date || '');
        } else if (sortField === 'merchant') {
          comparison = (a.merchant_name || '').localeCompare(b.merchant_name || '');
        } else if (sortField === 'amount') {
          comparison = (a.total_amount || 0) - (b.total_amount || 0);
        } else if (sortField === 'confidence') {
          comparison = (a.ocr_confidence ?? 0.9) - (b.ocr_confidence ?? 0.9);
        } else if (sortField === 'items') {
          comparison = (a.line_items?.length || 1) - (b.line_items?.length || 1);
        } else if (sortField === 'latency') {
          comparison = (a.ocr_latency_ms || 340) - (b.ocr_latency_ms || 340);
        }
        return sortOrder === 'asc' ? comparison : -comparison;
      })
    : filteredReceipts;

  // Header column sorting handler
  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('desc');
    }
  };

  const renderSortIndicator = (field: SortField) => {
    if (sortField !== field) {
      return <ArrowUpDown className="w-3 h-3 text-slate-400 opacity-60 inline-block ml-1" />;
    }
    return sortOrder === 'asc' ? (
      <ArrowUp className="w-3 h-3 text-slate-900 inline-block ml-1" />
    ) : (
      <ArrowDown className="w-3 h-3 text-slate-900 inline-block ml-1" />
    );
  };

  const handleClearFilters = () => {
    onSearchChange('');
    onTypeFilterChange('ALL');
    setStatusFilter('ALL');
    onDateStartChange('');
    onDateEndChange('');
  };

  const hasActiveFilters = Boolean(
    search || typeFilter !== 'ALL' || statusFilter !== 'ALL' || dateStartFilter || dateEndFilter
  );

  return (
    <div className="flex flex-col bg-white border border-[#CBD5E1] rounded-2xl overflow-hidden h-full select-none">
      {/* ── Sub-Header: Clean crisp white surface with black RL badge ── */}
      <div className="bg-white border-b border-[#CBD5E1] px-5 py-3 flex items-center justify-between text-slate-900">
        <div className="flex items-center gap-2.5">
          <div className="w-6 h-6 bg-black text-white rounded-lg flex items-center justify-center p-1 shrink-0">
            <ProjectIcon name="ledger" className="w-4 h-4 text-white" />
          </div>
          <span className="font-mono font-bold text-xs tracking-wider uppercase text-slate-900">
            WORKSPACE B: INGESTION AUDIT LEDGER
          </span>
          <span className="font-mono text-[10px] font-semibold bg-[#F1F5F9] text-slate-700 border border-[#CBD5E1] px-1.5 py-0.5 rounded">
            50% Split
          </span>
          {isMockMode && (
            <span className="flex items-center gap-1 font-mono text-[10px] font-bold bg-amber-50 text-amber-900 border border-amber-300 px-2 py-0.5 rounded">
              <WifiOff className="w-3 h-3 text-amber-700" />
              OFFLINE FIXTURES
            </span>
          )}
        </div>

        {/* Quick CSV Export */}
        <a
          href={api.getExportCsvUrl(2026, 10)}
          download
          className="flex items-center gap-1.5 bg-white hover:bg-slate-100 text-slate-800 font-mono text-xs font-semibold px-2.5 py-1 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
          title="Download streaming CSV ledger export"
        >
          <Download className="w-3.5 h-3.5 text-slate-500" />
          <span>Export CSV</span>
        </a>
      </div>

      {/* ── Search & Multi-Column Filter Bar ───────────────────────────────── */}
      <div className="bg-[#F8FAFC] border-b border-[#CBD5E1] p-3 flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-2.5 font-mono text-xs">
        {/* Search Input with '/' hotkey badge */}
        <div className="relative w-full lg:w-72">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
          <input
            ref={searchInputRef}
            type="text"
            value={search}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Search merchant, items... (key '/')"
            className="w-full bg-white font-mono text-xs text-slate-900 border border-[#CBD5E1] focus:border-black focus:ring-1 focus:ring-black pl-9 pr-8 py-2 rounded-xl outline-none transition-colors placeholder:text-slate-400"
          />
          <kbd className="absolute right-2.5 top-2.5 text-[10px] bg-slate-100 text-slate-500 border border-slate-300 px-1 rounded pointer-events-none">
            /
          </kbd>
        </div>

        {/* Filters Row: Type, Status, Date Range */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 lg:pb-0 flex-wrap">
          {/* Receipt Type Filter Buttons */}
          <div className="flex items-center border border-[#CBD5E1] rounded-xl bg-white overflow-hidden">
            {(['ALL', 'PRINTED', 'HANDWRITTEN'] as ReceiptTypeFilter[]).map((t, idx) => (
              <button
                key={t}
                type="button"
                onClick={() => onTypeFilterChange(t)}
                className={`px-2.5 py-1.5 text-[11px] font-semibold transition-colors cursor-pointer ${
                  idx > 0 ? 'border-l border-[#CBD5E1]' : ''
                } ${
                  typeFilter === t
                    ? 'bg-black text-white'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
              >
                {t === 'ALL' ? 'All Types' : t === 'PRINTED' ? 'Printed' : 'Handwritten'}
              </button>
            ))}
          </div>

          {/* Status Filter Dropdown */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as ReceiptStatusFilter)}
            className="bg-white border border-[#CBD5E1] text-slate-800 text-[11px] font-semibold rounded-xl px-2.5 py-1.5 outline-none cursor-pointer focus:border-black"
          >
            <option value="ALL">All Statuses</option>
            <option value="PROCESSED">Processed</option>
            <option value="PENDING_REVIEW">Pending Review</option>
            <option value="FLAGGED">Flagged</option>
            <option value="DUPLICATE">Duplicate</option>
            <option value="FAILED">Failed</option>
          </select>

          {/* Date Range Picker */}
          <div className="flex items-center gap-1.5 bg-white border border-[#CBD5E1] px-2.5 py-1.5 rounded-xl text-[11px]">
            <Calendar className="w-3.5 h-3.5 text-slate-400" />
            <input
              type="date"
              value={dateStartFilter}
              onChange={(e) => onDateStartChange(e.target.value)}
              className="outline-none bg-transparent text-slate-800 font-semibold"
              title="Start Date"
            />
            <span className="text-slate-400">to</span>
            <input
              type="date"
              value={dateEndFilter}
              onChange={(e) => onDateEndChange(e.target.value)}
              className="outline-none bg-transparent text-slate-800 font-semibold"
              title="End Date"
            />
          </div>

          {/* Clear Filters Button */}
          {hasActiveFilters && (
            <button
              type="button"
              onClick={handleClearFilters}
              className="flex items-center gap-1 bg-white hover:bg-slate-100 text-slate-700 border border-[#CBD5E1] px-2 py-1.5 rounded-xl text-[11px] font-semibold transition-colors cursor-pointer"
              title="Reset all search and filter fields"
            >
              <RotateCcw className="w-3 h-3 text-slate-500" />
              <span>Reset</span>
            </button>
          )}
        </div>
      </div>

      {/* ── High-Density Grid (Table) ───────────────────────────────────────── */}
      <div className="flex-1 overflow-auto min-h-[380px]">
        <table className="w-full text-left text-xs font-mono border-collapse">
          <thead className="bg-[#F8FAFC] border-b border-[#CBD5E1] text-slate-700 font-bold uppercase text-[10px] sticky top-0 z-10">
            <tr>
              <th
                onClick={() => handleSort('merchant')}
                className="py-2.5 px-3 cursor-pointer hover:bg-slate-200 transition-colors"
              >
                Store Name {renderSortIndicator('merchant')}
              </th>
              <th
                onClick={() => handleSort('date')}
                className="py-2.5 px-3 cursor-pointer hover:bg-slate-200 transition-colors"
              >
                Date {renderSortIndicator('date')}
              </th>
              <th
                onClick={() => handleSort('items')}
                className="py-2.5 px-3 text-center cursor-pointer hover:bg-slate-200 transition-colors"
              >
                Items {renderSortIndicator('items')}
              </th>
              <th
                onClick={() => handleSort('amount')}
                className="py-2.5 px-3 text-right cursor-pointer hover:bg-slate-200 transition-colors"
              >
                Total Spend {renderSortIndicator('amount')}
              </th>
              <th
                onClick={() => handleSort('confidence')}
                className="py-2.5 px-3 text-center cursor-pointer hover:bg-slate-200 transition-colors"
              >
                Confidence {renderSortIndicator('confidence')}
              </th>
              <th className="py-2.5 px-3">
                pHash Fingerprint
              </th>
              <th
                onClick={() => handleSort('latency')}
                className="py-2.5 px-3 text-center cursor-pointer hover:bg-slate-200 transition-colors"
              >
                OCR Latency {renderSortIndicator('latency')}
              </th>
              <th className="py-2.5 px-3 text-center">
                Status
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200 bg-white">
            {isLoading ? (
              // Loading Skeleton State (5 high-density rows)
              Array.from({ length: 5 }).map((_, idx) => (
                <tr key={idx} className="animate-pulse">
                  <td className="py-3 px-3">
                    <div className="w-36 h-3 bg-slate-200 rounded"></div>
                    <div className="w-20 h-2 bg-slate-100 rounded mt-1.5"></div>
                  </td>
                  <td className="py-3 px-3">
                    <div className="w-20 h-3 bg-slate-200 rounded"></div>
                  </td>
                  <td className="py-3 px-3 text-center">
                    <div className="w-6 h-3 bg-slate-200 rounded mx-auto"></div>
                  </td>
                  <td className="py-3 px-3 text-right">
                    <div className="w-24 h-3 bg-slate-200 rounded ml-auto"></div>
                  </td>
                  <td className="py-3 px-3 text-center">
                    <div className="w-12 h-3 bg-slate-200 rounded mx-auto"></div>
                  </td>
                  <td className="py-3 px-3">
                    <div className="w-28 h-3 bg-slate-100 rounded"></div>
                  </td>
                  <td className="py-3 px-3 text-center">
                    <div className="w-12 h-3 bg-slate-100 rounded mx-auto"></div>
                  </td>
                  <td className="py-3 px-3 text-center">
                    <div className="w-16 h-4 bg-slate-200 rounded mx-auto"></div>
                  </td>
                </tr>
              ))
            ) : isError ? (
              // Error / Unavailable Backend State
              <tr>
                <td colSpan={8} className="py-12 text-center text-slate-500">
                  <div className="max-w-md mx-auto space-y-3 bg-red-50 border border-red-200 p-6 rounded-2xl font-mono text-xs">
                    <AlertCircle className="w-8 h-8 text-red-600 mx-auto" />
                    <div className="font-bold text-red-900 text-sm">
                      Backend Gateway Unreachable
                    </div>
                    <div className="text-[11px] text-red-800 leading-relaxed">
                      Unable to retrieve receipt records from /api/v1/analytics/receipts. Verify the backend
                      is running or transition to Offline Dev Mode.
                    </div>
                    <div className="pt-2 flex items-center justify-center gap-2">
                      {onRetry && (
                        <button
                          type="button"
                          onClick={onRetry}
                          className="bg-red-800 hover:bg-red-900 text-white font-bold px-3 py-1.5 rounded-lg transition-colors cursor-pointer"
                        >
                          Retry Request
                        </button>
                      )}
                      {onSwitchToMockMode && (
                        <button
                          type="button"
                          onClick={onSwitchToMockMode}
                          className="bg-slate-900 hover:bg-black text-white font-bold px-3 py-1.5 rounded-lg transition-colors cursor-pointer flex items-center gap-1.5"
                        >
                          <WifiOff className="w-3.5 h-3.5 text-amber-400" />
                          <span>Switch to Offline Dev Mode</span>
                        </button>
                      )}
                    </div>
                  </div>
                </td>
              </tr>
            ) : sortedReceipts.length === 0 ? (
              // Clean Zero-Data Empty State
              <tr>
                <td colSpan={8} className="py-12 text-center text-slate-400">
                  <div className="space-y-2">
                    <div className="font-bold text-slate-700 text-sm">No Receipts Found</div>
                    <div className="text-xs text-slate-500 max-w-sm mx-auto font-sans">
                      Ledger is empty or no records match the active search criteria.
                    </div>
                    {hasActiveFilters && (
                      <div className="pt-2">
                        <button
                          type="button"
                          onClick={handleClearFilters}
                          className="inline-flex items-center gap-1.5 bg-black hover:bg-slate-800 text-white font-mono text-xs font-semibold px-3 py-1.5 rounded-xl transition-colors cursor-pointer"
                        >
                          <RotateCcw className="w-3.5 h-3.5" />
                          <span>Clear All Active Filters</span>
                        </button>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            ) : (
              // High-Density Data Rows
              sortedReceipts.map((rcpt, idx) => {
                const isSelected = idx === selectedRowIndex;
                const itemsCount = rcpt.line_items ? rcpt.line_items.length : 1;
                const pHashSample = rcpt.phash_64 || 'a1b2c3d4e5f67890';
                const latencyMs = rcpt.ocr_latency_ms || 340;
                const confScore = rcpt.ocr_confidence ?? 0.9;
                const confPct = Math.round(confScore * 100);

                return (
                  <tr
                    key={rcpt.id || idx}
                    onClick={() => {
                      onSelectRowIndex(idx);
                      onOpenInspector(rcpt);
                    }}
                    className={`cursor-pointer transition-colors ${
                      isSelected
                        ? 'bg-blue-50 text-blue-950 font-semibold border-l-4 border-l-blue-600'
                        : 'hover:bg-[#F8FAFC] text-slate-800'
                    }`}
                  >
                    {/* Store Name & ID */}
                    <td className="py-2.5 px-3">
                      <div dir="auto" className="font-semibold text-slate-900 truncate max-w-[200px]" title={rcpt.merchant_name || 'Retail Superstore'}>
                        {rcpt.merchant_name || 'Retail Superstore'}
                      </div>
                      <div className="text-[10px] text-slate-400 font-normal mt-0.5">
                        Type: {rcpt.receipt_type || 'PRINTED'}
                      </div>
                    </td>

                    {/* Date */}
                    <td className="py-2.5 px-3 text-slate-600 whitespace-nowrap">
                      {formatDate(rcpt.receipt_date)}
                    </td>

                    {/* Items Count */}
                    <td className="py-2.5 px-3 text-center text-slate-600">
                      {itemsCount}
                    </td>

                    {/* Total Spend (PKR, tabular numerals) */}
                    <td className="py-2.5 px-3 text-right font-bold text-slate-900 whitespace-nowrap tabular-nums">
                      {formatPKR(rcpt.total_amount)}
                    </td>

                    {/* OCR Confidence */}
                    <td className="py-2.5 px-3 text-center whitespace-nowrap">
                      <span
                        className={`inline-block px-1.5 py-0.5 rounded text-[10px] font-bold border ${
                          confScore >= 0.85
                            ? 'bg-emerald-50 text-emerald-800 border-emerald-300'
                            : confScore >= 0.7
                            ? 'bg-amber-50 text-amber-800 border-amber-300'
                            : 'bg-red-50 text-red-800 border-red-300'
                        }`}
                      >
                        {confPct}%
                      </span>
                    </td>

                    {/* pHash Fingerprint */}
                    <td className="py-2.5 px-3 font-mono text-[11px] text-slate-500 whitespace-nowrap">
                      <span className="bg-slate-100 border border-slate-200 px-1.5 py-0.5 rounded">
                        {pHashSample}
                      </span>
                    </td>

                    {/* OCR Latency */}
                    <td className="py-2.5 px-3 text-center whitespace-nowrap tabular-nums text-slate-600">
                      <span className="bg-slate-100 border border-slate-200 px-1.5 py-0.5 rounded text-[11px]">
                        {latencyMs}ms
                      </span>
                    </td>

                    {/* Status Pill */}
                    <td className="py-2.5 px-3 text-center whitespace-nowrap">
                      <span
                        className={`inline-block px-2 py-0.5 rounded text-[10px] font-bold uppercase border ${
                          rcpt.status === 'PROCESSED'
                            ? 'bg-emerald-100 text-emerald-800 border-emerald-300'
                            : rcpt.status === 'DUPLICATE'
                            ? 'bg-purple-100 text-purple-800 border-purple-300'
                            : rcpt.status === 'FAILED'
                            ? 'bg-red-100 text-red-800 border-red-300'
                            : 'bg-amber-100 text-amber-800 border-amber-300'
                        }`}
                      >
                        {rcpt.status || 'PROCESSED'}
                      </span>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* ── Table Footer & Pagination ───────────────────────────────────────── */}
      <div className="bg-[#F8FAFC] border-t border-[#CBD5E1] px-5 py-2.5 flex flex-col sm:flex-row items-center justify-between text-xs font-mono text-slate-600 gap-2">
        <div className="flex items-center gap-2">
          <span>
            Showing page <strong>{page}</strong> of <strong>{totalPages}</strong> ({totalCount} receipts total)
          </span>
          <span className="text-slate-400">•</span>
          <span className="text-[11px] text-slate-500">
            Navigate: <kbd className="text-[9px] bg-white border border-slate-300 px-1 rounded">J</kbd>/<kbd className="text-[9px] bg-white border border-slate-300 px-1 rounded">K</kbd> • Inspect: <kbd className="text-[9px] bg-white border border-slate-300 px-1 rounded">Space</kbd>
          </span>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(1, page - 1))}
            disabled={page <= 1}
            className="flex items-center gap-1 px-2.5 py-1 bg-white hover:bg-slate-100 disabled:opacity-30 rounded-lg border border-[#CBD5E1] text-slate-700 cursor-pointer transition-colors"
          >
            <ChevronLeft className="w-3.5 h-3.5" />
            <span>Prev</span>
          </button>
          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages, page + 1))}
            disabled={page >= totalPages}
            className="flex items-center gap-1 px-2.5 py-1 bg-white hover:bg-slate-100 disabled:opacity-30 rounded-lg border border-[#CBD5E1] text-slate-700 cursor-pointer transition-colors"
          >
            <span>Next</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
};
