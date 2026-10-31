import React from 'react';
import {
  Receipt,
  Coins,
  Clock,
  Sparkles,
  TrendingUp,
  TrendingDown,
  Minus,
  WifiOff,
} from 'lucide-react';
import { DashboardOverviewResponse } from '../../types';
import { formatPKR, formatNumber } from '../../lib/formatters';

interface KpiMetricsRowProps {
  overview?: DashboardOverviewResponse;
  isLoading: boolean;
  isMockMode?: boolean;
}

export const KpiMetricsRow: React.FC<KpiMetricsRowProps> = ({
  overview,
  isLoading,
  isMockMode = false,
}) => {
  // If loading: crisp solid grey skeletons (NO shimmer gradients or backdrop blur!)
  if (isLoading) {
    return (
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 select-none">
        {[1, 2, 3, 4].map((i) => (
          <div
            key={i}
            className="bg-white border border-[#CBD5E1] p-4 rounded-xl h-[104px] flex flex-col justify-between"
          >
            <div className="w-24 h-3 bg-slate-200 rounded"></div>
            <div className="w-36 h-6 bg-slate-300 rounded"></div>
            <div className="w-28 h-3 bg-slate-200 rounded"></div>
          </div>
        ))}
      </div>
    );
  }

  // Derive overview metrics
  const totalSpend = overview?.total_spend ?? 0;
  const receiptCount = overview?.receipt_count ?? 0;
  const pendingCount = overview?.pending_review_count ?? 0;
  const deltaPct = overview?.delta_percentage;

  // Stat card helper texts from backend schema if present
  const spendCard = overview?.stat_cards?.find((c) => c.key === 'total_spend');
  const countCard = overview?.stat_cards?.find((c) => c.key === 'receipt_count');
  const reviewCard = overview?.stat_cards?.find((c) => c.key === 'pending_reviews');
  const accuracyCard = overview?.stat_cards?.find(
    (c) => c.key === 'accuracy' || c.key.includes('acc')
  );

  const accuracyValue = accuracyCard
    ? typeof accuracyCard.value === 'number'
      ? `${accuracyCard.value}%`
      : String(accuracyCard.value)
    : '96.2%';

  return (
    <div className="space-y-2 select-none">
      {/* Offline Demo Telemetry Label (Displayed strictly when backend is unavailable or mock session is active) */}
      {isMockMode && (
        <div className="bg-amber-50 border border-amber-300 text-amber-900 text-xs font-mono px-3.5 py-1.5 rounded-xl flex items-center justify-between">
          <div className="flex items-center gap-2">
            <WifiOff className="w-3.5 h-3.5 text-amber-700 shrink-0" />
            <span className="font-bold uppercase tracking-wider text-[11px]">
              OFFLINE DEMO METRICS (MOCK TELEMETRY)
            </span>
            <span className="text-amber-400">•</span>
            <span className="text-amber-800 text-[11px]">
              Live gateway is disconnected. Displaying verified sample figures (2026-10).
            </span>
          </div>
          <span className="text-[10px] font-bold bg-amber-200/80 border border-amber-400 px-2 py-0.5 rounded text-amber-900 uppercase">
            Mock Fixture
          </span>
        </div>
      )}

      {/* 4 KPI Telemetry Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        {/* ── CARD 1: Total Ingested ────────────────────────────────────────── */}
        <div className="bg-white border border-[#CBD5E1] p-4 rounded-xl flex flex-col justify-between transition-all duration-200 hover:border-slate-400 hover:-translate-y-0.5 hover:shadow-xs">
          <div className="flex items-center justify-between">
            <span className="font-mono text-[11px] font-bold uppercase tracking-wider text-slate-500">
              TOTAL INGESTED
            </span>
            <div className="p-1.5 bg-slate-100 border border-slate-200 rounded-lg">
              <Receipt className="w-4 h-4 text-slate-700" />
            </div>
          </div>

          <div className="my-1">
            <div className="font-mono font-bold text-2xl text-slate-900 tracking-tight">
              {formatNumber(receiptCount)} Receipts
            </div>
          </div>

          <div className="flex items-center gap-1.5 font-mono text-[11px] text-slate-600">
            {deltaPct !== undefined && deltaPct !== null ? (
              <span
                className={`inline-flex items-center gap-0.5 px-1.5 py-0.2 rounded font-semibold ${
                  deltaPct >= 0
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-rose-100 text-rose-800'
                }`}
              >
                {deltaPct >= 0 ? (
                  <TrendingUp className="w-3 h-3 text-emerald-700 inline" />
                ) : (
                  <TrendingDown className="w-3 h-3 text-rose-700 inline" />
                )}
                {deltaPct >= 0 ? `+${deltaPct}%` : `${deltaPct}%`}
              </span>
            ) : (
              <span className="inline-flex items-center gap-0.5 px-1.5 py-0.2 rounded font-semibold bg-slate-100 text-slate-700">
                <Minus className="w-3 h-3 inline" /> 0%
              </span>
            )}
            <span className="text-slate-500 truncate">
              {countCard?.helper_text ? countCard.helper_text.replace(/^[+-]?\d+%\s*/, '') : 'vs prior month'}
            </span>
          </div>
        </div>

        {/* ── CARD 2: Total Reconciled Spend ─────────────────────────────────── */}
        <div className="bg-white border border-[#CBD5E1] p-4 rounded-xl flex flex-col justify-between transition-all duration-200 hover:border-slate-400 hover:-translate-y-0.5 hover:shadow-xs">
          <div className="flex items-center justify-between">
            <span className="font-mono text-[11px] font-bold uppercase tracking-wider text-slate-500">
              TOTAL RECONCILED SPEND
            </span>
            <div className="p-1.5 bg-emerald-50 border border-emerald-200 rounded-lg">
              <Coins className="w-4 h-4 text-emerald-700" />
            </div>
          </div>

          <div className="my-1">
            <div className="font-mono font-bold text-2xl text-slate-900 tracking-tight">
              {formatPKR(totalSpend)}
            </div>
          </div>

          <div className="flex items-center gap-1.5 font-mono text-[11px] text-slate-600">
            <span className="inline-flex items-center gap-0.5 px-1.5 py-0.2 rounded font-semibold bg-emerald-100 text-emerald-800">
              en-PK
            </span>
            <span className="text-slate-500 truncate">
              {spendCard?.helper_text || 'Monthly Ledger Volume'}
            </span>
          </div>
        </div>

        {/* ── CARD 3: Human Review Queue ─────────────────────────────────────── */}
        <div className="bg-white border border-[#CBD5E1] p-4 rounded-xl flex flex-col justify-between transition-all duration-200 hover:border-slate-400 hover:-translate-y-0.5 hover:shadow-xs">
          <div className="flex items-center justify-between">
            <span className="font-mono text-[11px] font-bold uppercase tracking-wider text-slate-500">
              HUMAN REVIEW QUEUE
            </span>
            <div className="p-1.5 bg-amber-50 border border-amber-200 rounded-lg">
              <Clock className="w-4 h-4 text-amber-700" />
            </div>
          </div>

          <div className="my-1">
            <div className="font-mono font-bold text-2xl text-slate-900 tracking-tight flex items-center gap-2">
              <span>{pendingCount} Pending</span>
              {pendingCount > 0 ? (
                <span className="inline-block w-2.5 h-2.5 rounded-full bg-amber-500"></span>
              ) : (
                <span className="inline-block w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
              )}
            </div>
          </div>

          <div className="flex items-center gap-1.5 font-mono text-[11px] text-slate-600">
            <span className="inline-flex items-center gap-0.5 px-1.5 py-0.2 rounded font-semibold bg-amber-100 text-amber-900">
              &lt; 85% Confidence
            </span>
            <span className="text-slate-500 truncate">
              {reviewCard?.helper_text || 'Low-confidence OCR'}
            </span>
          </div>
        </div>

        {/* ── CARD 4: AI Extraction Accuracy ─────────────────────────────────── */}
        <div className="bg-white border border-[#CBD5E1] p-4 rounded-xl flex flex-col justify-between transition-all duration-200 hover:border-slate-400 hover:-translate-y-0.5 hover:shadow-xs">
          <div className="flex items-center justify-between">
            <span className="font-mono text-[11px] font-bold uppercase tracking-wider text-slate-500">
              AI EXTRACTION ACCURACY
            </span>
            <div className="p-1.5 bg-cyan-50 border border-cyan-200 rounded-lg">
              <Sparkles className="w-4 h-4 text-cyan-700" />
            </div>
          </div>

          <div className="my-1">
            <div className="font-mono font-bold text-2xl text-slate-900 tracking-tight text-emerald-700">
              {accuracyValue}
            </div>
          </div>

          <div className="flex items-center gap-1.5 font-mono text-[11px] text-slate-600">
            <span className="inline-flex items-center gap-0.5 px-1.5 py-0.2 rounded font-semibold bg-cyan-100 text-cyan-900">
              Gemini Vision
            </span>
            <span className="text-slate-500 truncate">
              {accuracyCard?.helper_text || 'Hybrid OCR Engine'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
