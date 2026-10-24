import React from 'react';
import { 
  FileText, 
  Banknote, 
  AlertTriangle, 
  CheckCircle2, 
  ArrowUpRight 
} from 'lucide-react';

export default function KpiMetricsRow({ overview }) {
  const totalSpend = overview?.total_spend !== undefined 
    ? `PKR ${overview.total_spend.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` 
    : 'PKR 184,250.00';
    
  const receiptsCount = overview?.receipt_count !== undefined 
    ? `${overview.receipt_count} Receipts` 
    : '148 Receipts';
    
  const pendingCount = overview?.pending_review_count !== undefined 
    ? `${overview.pending_review_count} Pending` 
    : '7 Pending';
    
  const deltaPct = overview?.delta_percentage !== undefined 
    ? overview.delta_percentage 
    : 14.0;

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 px-5 py-4">
      {/* 1. Ingested Receipts */}
      <div className="bg-white border border-[#CBD5E1] rounded p-4 shadow-none">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[11px] font-mono font-bold tracking-wider text-slate-500 uppercase">
            TOTAL INGESTED
          </span>
          <span className="inline-flex items-center gap-0.5 text-xs font-mono font-semibold text-emerald-700 bg-emerald-100 border border-emerald-300 px-1.5 py-0.5 rounded">
            <ArrowUpRight className="w-3 h-3" />
            +{deltaPct}%
          </span>
        </div>
        <div className="font-mono font-bold text-2xl text-slate-900 tracking-tight">
          {receiptsCount}
        </div>
        <div className="text-xs text-slate-500 font-sans mt-1 flex items-center justify-between">
          <span>Primary batch ingestion</span>
          <span className="font-mono text-[11px] text-slate-400">130 prior month</span>
        </div>
      </div>

      {/* 2. Total Reconciled Spend */}
      <div className="bg-white border border-[#CBD5E1] rounded p-4 shadow-none">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[11px] font-mono font-bold tracking-wider text-slate-500 uppercase">
            TOTAL RECONCILED SPEND
          </span>
          <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
        </div>
        <div className="font-mono font-bold text-2xl text-slate-900 tracking-tight">
          {totalSpend}
        </div>
        <div className="text-xs text-slate-500 font-sans mt-1 flex items-center justify-between">
          <span>October 2026 Fiscal Ledger</span>
          <span className="font-mono text-[11px] text-slate-400">+PKR 22,630 delta</span>
        </div>
      </div>

      {/* 3. Human Review Queue */}
      <div className="bg-white border border-[#CBD5E1] rounded p-4 shadow-none">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[11px] font-mono font-bold tracking-wider text-slate-500 uppercase">
            HUMAN REVIEW QUEUE
          </span>
          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-semibold text-amber-800 bg-amber-100 border border-amber-300 px-1.5 py-0.5 rounded">
            <AlertTriangle className="w-3 h-3 text-amber-700" />
            Action Req.
          </span>
        </div>
        <div className="font-mono font-bold text-2xl text-amber-700 tracking-tight">
          {pendingCount}
        </div>
        <div className="text-xs text-slate-500 font-sans mt-1 flex items-center justify-between">
          <span>OCR confidence &lt; 85%</span>
          <span className="font-mono text-[11px] text-slate-400">Triage Desk A</span>
        </div>
      </div>

      {/* 4. AI Extraction Accuracy */}
      <div className="bg-white border border-[#CBD5E1] rounded p-4 shadow-none">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[11px] font-mono font-bold tracking-wider text-slate-500 uppercase">
            AI EXTRACTION ACCURACY
          </span>
          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-semibold text-blue-800 bg-blue-100 border border-blue-300 px-1.5 py-0.5 rounded">
            <CheckCircle2 className="w-3 h-3 text-blue-700" />
            Benchmarked
          </span>
        </div>
        <div className="font-mono font-bold text-2xl text-blue-700 tracking-tight">
          96.2%
        </div>
        <div className="text-xs text-slate-500 font-sans mt-1 flex items-center justify-between">
          <span>Gemini 3.5 Flash-Lite & Vision</span>
          <span className="font-mono text-[11px] text-slate-400">p95 385ms</span>
        </div>
      </div>
    </div>
  );
}
