import React, { useState, useEffect, useRef } from 'react';
import { 
  Database, 
  Search, 
  Download, 
  Hash, 
  Calendar, 
  ChevronRight, 
  ChevronLeft, 
  Filter, 
  ExternalLink,
  SlidersHorizontal,
  ArrowUpDown
} from 'lucide-react';
import { api } from '../services/api';
import SlideOutDrawer from './SlideOutDrawer';

export default function WorkspaceB_AuditLedger({ 
  onSelectReceipt, 
  selectedReceiptId,
  searchInputRef,
  refreshTrigger = 0
}) {
  const [receipts, setReceipts] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('ALL'); // 'ALL' | 'PRINTED' | 'HANDWRITTEN'
  const [statusFilter, setStatusFilter] = useState('ALL'); // 'ALL' | 'PROCESSED' | 'PENDING_REVIEW'
  const [loading, setLoading] = useState(false);

  // Keyboard row navigation index
  const [selectedRowIndex, setSelectedRowIndex] = useState(0);

  // Slide-out Drawer
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [inspectedReceipt, setInspectedReceipt] = useState(null);

  // Load receipts from backend
  const fetchReceipts = async () => {
    setLoading(true);
    try {
      const data = await api.getReceipts({
        page,
        pageSize,
        search,
      });
      setReceipts(data.receipts || []);
      setTotalCount(data.total || 0);
    } catch (err) {
      console.error("Failed to load receipts ledger:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReceipts();
  }, [page, pageSize, search, refreshTrigger]);

  // Client-side filtering for type and status if needed
  const filteredReceipts = receipts.filter((r) => {
    if (typeFilter !== 'ALL' && (r.receipt_type || 'PRINTED') !== typeFilter) {
      return false;
    }
    if (statusFilter !== 'ALL' && (r.status || 'PROCESSED') !== statusFilter) {
      return false;
    }
    return true;
  });

  // Keep selectedRowIndex in bounds
  useEffect(() => {
    if (selectedRowIndex >= filteredReceipts.length) {
      setSelectedRowIndex(Math.max(0, filteredReceipts.length - 1));
    }
  }, [filteredReceipts.length]);

  // Handle open drawer
  const openInspector = (receipt) => {
    setInspectedReceipt(receipt);
    setDrawerOpen(true);
  };

  // Keyboard shortcut listener for Audit Ledger grid:
  // ↑ / ↓ or J / K: Select previous / next receipt row
  // Space: Open Slide-Out Inspector Drawer
  // Esc: Close Slide-Out Inspector Drawer
  useEffect(() => {
    const handleKeyDown = (e) => {
      // Don't intercept if typing in an input
      if (['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) {
        return;
      }

      if (e.key === 'ArrowDown' || e.key === 'j' || e.key === 'J') {
        e.preventDefault();
        setSelectedRowIndex((prev) => Math.min(filteredReceipts.length - 1, prev + 1));
      } else if (e.key === 'ArrowUp' || e.key === 'k' || e.key === 'K') {
        e.preventDefault();
        setSelectedRowIndex((prev) => Math.max(0, prev - 1));
      } else if (e.key === ' ' || e.code === 'Space') {
        e.preventDefault();
        if (filteredReceipts[selectedRowIndex]) {
          openInspector(filteredReceipts[selectedRowIndex]);
        }
      } else if (e.key === 'Escape') {
        setDrawerOpen(false);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [filteredReceipts, selectedRowIndex]);

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

  return (
    <div className="flex flex-col bg-white border border-[#CBD5E1] rounded overflow-hidden shadow-none h-full select-none">
      {/* Workspace Sub-Header */}
      <div className="bg-[#0F172A] border-b border-[#334155] px-4 py-2.5 flex items-center justify-between text-white">
        <div className="flex items-center gap-2">
          <Database className="w-4 h-4 text-cyan-400" />
          <span className="font-mono font-bold text-xs tracking-wider uppercase">
            WORKSPACE B: INGESTION AUDIT LEDGER
          </span>
          <span className="font-mono text-[11px] bg-slate-800 text-slate-300 border border-slate-700 px-1.5 py-0.2 rounded">
            50% Split
          </span>
        </div>

        {/* Quick CSV Export */}
        <a
          href={api.getExportCsvUrl(2026, 10)}
          download
          className="flex items-center gap-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 font-mono text-xs px-2.5 py-1 rounded border border-slate-700 transition-colors"
          title="Download streaming CSV ledger export"
        >
          <Download className="w-3.5 h-3.5 text-slate-300" />
          <span>Export CSV</span>
        </a>
      </div>

      {/* Search & Filter Bar */}
      <div className="bg-slate-50 border-b border-[#CBD5E1] p-3 flex flex-col md:flex-row items-center justify-between gap-3">
        {/* Search Input with '/' hotkey badge */}
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
          <input
            ref={searchInputRef}
            type="text"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            placeholder="Search merchant, items... (key '/')"
            className="w-full bg-white font-mono text-xs text-slate-900 border border-[#CBD5E1] focus:border-slate-800 focus:ring-1 focus:ring-slate-800 pl-9 pr-9 py-2 rounded outline-none"
          />
          <kbd className="absolute right-2.5 top-2 text-[10px] pointer-events-none">
            /
          </kbd>
        </div>

        {/* Filter Chips: Type (Printed/Handwritten) & Status */}
        <div className="flex items-center gap-2 w-full md:w-auto overflow-x-auto pb-1 md:pb-0 font-mono text-xs">
          <div className="flex items-center border border-[#CBD5E1] rounded bg-white overflow-hidden">
            <button
              onClick={() => setTypeFilter('ALL')}
              className={`px-2.5 py-1 text-[11px] font-semibold transition-colors ${
                typeFilter === 'ALL'
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              All Types
            </button>
            <button
              onClick={() => setTypeFilter('PRINTED')}
              className={`px-2.5 py-1 text-[11px] font-semibold border-l border-[#CBD5E1] transition-colors ${
                typeFilter === 'PRINTED'
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              Printed
            </button>
            <button
              onClick={() => setTypeFilter('HANDWRITTEN')}
              className={`px-2.5 py-1 text-[11px] font-semibold border-l border-[#CBD5E1] transition-colors ${
                typeFilter === 'HANDWRITTEN'
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              Handwritten
            </button>
          </div>

          <div className="flex items-center border border-[#CBD5E1] rounded bg-white overflow-hidden">
            <button
              onClick={() => setStatusFilter('ALL')}
              className={`px-2.5 py-1 text-[11px] font-semibold transition-colors ${
                statusFilter === 'ALL'
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              All Status
            </button>
            <button
              onClick={() => setStatusFilter('PROCESSED')}
              className={`px-2.5 py-1 text-[11px] font-semibold border-l border-[#CBD5E1] transition-colors ${
                statusFilter === 'PROCESSED'
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              Processed
            </button>
            <button
              onClick={() => setStatusFilter('PENDING_REVIEW')}
              className={`px-2.5 py-1 text-[11px] font-semibold border-l border-[#CBD5E1] transition-colors ${
                statusFilter === 'PENDING_REVIEW'
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              Pending
            </button>
          </div>
        </div>
      </div>

      {/* High-Density Grid (Table) */}
      <div className="flex-1 overflow-auto min-h-[400px]">
        <table className="w-full text-left text-xs font-mono border-collapse">
          <thead className="bg-slate-100 border-b border-[#CBD5E1] text-slate-700 font-bold uppercase text-[10px] sticky top-0 z-10">
            <tr>
              <th className="py-2 px-3">Store Name</th>
              <th className="py-2 px-3">Date</th>
              <th className="py-2 px-3 text-center">Items</th>
              <th className="py-2 px-3 text-right">Total Spend</th>
              <th className="py-2 px-3">pHash Fingerprint</th>
              <th className="py-2 px-3 text-center">Latency / Conf</th>
              <th className="py-2 px-3 text-center">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {loading ? (
              <tr>
                <td colSpan={7} className="py-8 text-center text-slate-400">
                  Loading ledger entries...
                </td>
              </tr>
            ) : filteredReceipts.length === 0 ? (
              <tr>
                <td colSpan={7} className="py-8 text-center text-slate-400">
                  No receipts match the active filter criteria.
                </td>
              </tr>
            ) : (
              filteredReceipts.map((rcpt, idx) => {
                const isSelected = idx === selectedRowIndex;
                const itemsCount = rcpt.line_items ? rcpt.line_items.length : 3;
                const pHashSample = rcpt.phash_64 || `e4a8f102c918${idx}4ab`.slice(0, 16);
                const confScore = Math.round((rcpt.ocr_confidence || 0.94) * 100);

                return (
                  <tr
                    key={rcpt.id || idx}
                    onClick={() => {
                      setSelectedRowIndex(idx);
                      openInspector(rcpt);
                    }}
                    className={`cursor-pointer transition-colors ${
                      isSelected
                        ? 'bg-blue-50/90 text-blue-950 font-semibold border-l-4 border-l-blue-600'
                        : 'hover:bg-slate-50 text-slate-800'
                    }`}
                  >
                    {/* Store Name */}
                    <td className="py-2 px-3">
                      <div className="font-semibold text-slate-900 truncate max-w-[190px]">
                        {rcpt.merchant_name || 'Retail Superstore'}
                      </div>
                      <div className="text-[10px] text-slate-400 font-normal">
                        Type: {rcpt.receipt_type || 'PRINTED'}
                      </div>
                    </td>

                    {/* Date */}
                    <td className="py-2 px-3 text-slate-600 whitespace-nowrap">
                      {rcpt.receipt_date || '2026-10-18'}
                    </td>

                    {/* Items Count */}
                    <td className="py-2 px-3 text-center text-slate-600">
                      {itemsCount}
                    </td>

                    {/* Total Spend (PKR) */}
                    <td className="py-2 px-3 text-right font-bold text-slate-900 whitespace-nowrap">
                      PKR {rcpt.total_amount?.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    </td>

                    {/* pHash */}
                    <td className="py-2 px-3 font-mono text-[11px] text-slate-500 whitespace-nowrap">
                      <span className="bg-slate-100 border border-slate-200 px-1.5 py-0.5 rounded">
                        {pHashSample}
                      </span>
                    </td>

                    {/* Latency / Confidence */}
                    <td className="py-2 px-3 text-center whitespace-nowrap">
                      <span className={`inline-block px-1.5 py-0.2 rounded text-[10px] font-bold ${
                        confScore >= 85
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-amber-100 text-amber-800'
                      }`}>
                        {confScore}%
                      </span>
                    </td>

                    {/* Status Pill */}
                    <td className="py-2 px-3 text-center whitespace-nowrap">
                      <span className={`inline-block px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                        rcpt.status === 'PROCESSED'
                          ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                          : 'bg-amber-100 text-amber-800 border border-amber-300'
                      }`}>
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

      {/* Pagination & Keyboard Navigation Status Ribbon */}
      <div className="bg-slate-50 border-t border-[#CBD5E1] p-3 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs font-mono text-slate-600">
        <div className="flex items-center gap-3">
          <span>
            Total Receipts: <strong>{totalCount}</strong>
          </span>
          <span className="hidden sm:inline text-slate-400">•</span>
          <span className="hidden sm:inline text-slate-500 text-[11px]">
            Row: <kbd>↑</kbd> <kbd>↓</kbd> or <kbd>J</kbd> <kbd>K</kbd> • Inspect: <kbd>Space</kbd>
          </span>
        </div>

        <div className="flex items-center gap-2">
          <span>
            Page {page} of {totalPages}
          </span>
          <div className="flex items-center border border-[#CBD5E1] rounded bg-white">
            <button
              onClick={() => setPage(Math.max(1, page - 1))}
              disabled={page <= 1}
              className="p-1 hover:bg-slate-100 disabled:opacity-30"
              title="Previous page"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={() => setPage(Math.min(totalPages, page + 1))}
              disabled={page >= totalPages}
              className="p-1 hover:bg-slate-100 disabled:opacity-30 border-l border-[#CBD5E1]"
              title="Next page"
            >
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      {/* Slide-Out Inspector Drawer */}
      <SlideOutDrawer
        receipt={inspectedReceipt}
        isOpen={drawerOpen}
        onClose={() => setDrawerOpen(false)}
      />
    </div>
  );
}
