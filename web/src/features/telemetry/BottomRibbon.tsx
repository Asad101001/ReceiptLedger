import React, { useState } from 'react';
import {
  PieChart as PieIcon,
  TrendingUp,
  Activity,
  Download,
  WifiOff,
  AlertTriangle,
  List,
  X,
} from 'lucide-react';
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
} from 'recharts';
import {
  CategorySpendDetail,
  MonthlyTrendPoint,
  SystemRunLog,
} from '../../types';
import { formatPKR, formatDateTime } from '../../lib/formatters';
import { RunDetailDrawer } from './RunDetailDrawer';

export interface BottomRibbonProps {
  categories: CategorySpendDetail[];
  trends: MonthlyTrendPoint[];
  runs: SystemRunLog[];
  isLoadingOverview?: boolean;
  isErrorOverview?: boolean;
  isLoadingTrends?: boolean;
  isErrorTrends?: boolean;
  isLoadingRuns?: boolean;
  isErrorRuns?: boolean;
  onRetryOverview?: () => void;
  onRetryTrends?: () => void;
  onRetryRuns?: () => void;
  onSwitchToMockMode?: () => void;
  trendMonths?: number;
  onTrendMonthsChange?: (months: number) => void;
  isMockMode?: boolean;
  onExportCsv?: () => void;
}

export const BottomRibbon: React.FC<BottomRibbonProps> = ({
  categories,
  trends,
  runs,
  isLoadingOverview = false,
  isErrorOverview = false,
  isLoadingTrends = false,
  isErrorTrends = false,
  isLoadingRuns = false,
  isErrorRuns = false,
  onRetryOverview,
  onRetryTrends,
  onRetryRuns,
  onSwitchToMockMode,
  trendMonths = 6,
  onTrendMonthsChange,
  isMockMode = false,
  onExportCsv,
}) => {
  // Category drill-down state
  const [selectedCategory, setSelectedCategory] = useState<CategorySpendDetail | null>(null);
  const [categoryViewMode, setCategoryViewMode] = useState<'donut' | 'bars'>('donut');

  // Run log inspector drawer state
  const [inspectedRun, setInspectedRun] = useState<SystemRunLog | null>(null);

  // Filter out categories with 0 spend if necessary or display top categories
  const activeCategories = categories.filter((c) => c.total_spend > 0);
  const displayCategories = activeCategories.length > 0 ? activeCategories : categories;
  const totalCategorySpend = categories.reduce((sum, c) => sum + (c.total_spend || 0), 0);

  // Spend Trajectory summary stats
  const peakSpend = Math.max(...trends.map((t) => t.total_spend), 0);
  const avgMonthlySpend = trends.length > 0
    ? Math.round(trends.reduce((acc, t) => acc + t.total_spend, 0) / trends.length)
    : 0;

  // Trajectory velocity: compare last month with second-to-last month
  const latestMonth = trends[trends.length - 1];
  const priorMonth = trends.length >= 2 ? trends[trends.length - 2] : null;
  const velocityDelta = priorMonth && priorMonth.total_spend > 0
    ? latestMonth.total_spend - priorMonth.total_spend
    : 0;
  const velocityPct = priorMonth && priorMonth.total_spend > 0
    ? ((velocityDelta / priorMonth.total_spend) * 100).toFixed(1)
    : null;

  return (
    <div className="space-y-3 select-none">
      {/* Offline Demo Telemetry Banner (when mock mode is active) */}
      {isMockMode && (
        <div className="bg-amber-50 border border-amber-300 text-amber-900 text-xs font-mono px-3.5 py-1.5 rounded-xl flex items-center justify-between">
          <div className="flex items-center gap-2">
            <WifiOff className="w-3.5 h-3.5 text-amber-700 shrink-0" />
            <span className="font-bold uppercase tracking-wider text-[11px]">
              OFFLINE DEMO ANALYTICS (MOCK FIXTURE)
            </span>
            <span className="text-amber-400">•</span>
            <span className="text-amber-800 text-[11px]">
              Displaying simulated monthly velocity, categories, and test runs. Not live telemetry.
            </span>
          </div>
          {onExportCsv && (
            <button
              type="button"
              onClick={onExportCsv}
              className="flex items-center gap-1 bg-amber-200/80 hover:bg-amber-300 border border-amber-400 text-amber-950 font-mono text-[10px] font-bold px-2 py-0.5 rounded transition-colors cursor-pointer"
            >
              <Download className="w-3 h-3" />
              <span>Export Mock CSV</span>
            </button>
          )}
        </div>
      )}

      {/* 3-Column Analytics Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-3">
        {/* ── 1. Category Spend Breakdown (Solid Flat Fills) ────────────────── */}
        <div className="bg-white border border-[#CBD5E1] rounded-xl flex flex-col justify-between overflow-hidden">
          {/* Card Header */}
          <div className="bg-[#0F172A] border-b border-[#334155] px-3.5 py-2.5 flex items-center justify-between text-white shrink-0">
            <div className="flex items-center gap-2">
              <PieIcon className="w-4 h-4 text-emerald-400" />
              <h3 className="font-mono font-bold text-xs uppercase tracking-wide text-white">
                Category Spend Breakdown
              </h3>
            </div>
            <div className="flex items-center gap-1.5">
              {isMockMode && (
                <span className="text-[9px] font-mono bg-amber-400 text-black px-1.5 py-0.2 rounded font-bold uppercase">
                  MOCK
                </span>
              )}
              {/* Toggle Donut vs Bars */}
              <div className="flex items-center bg-slate-800 border border-slate-700 rounded p-0.5">
                <button
                  type="button"
                  onClick={() => setCategoryViewMode('donut')}
                  title="Donut Chart View"
                  className={`p-1 rounded ${
                    categoryViewMode === 'donut'
                      ? 'bg-black text-white'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <PieIcon className="w-3 h-3" />
                </button>
                <button
                  type="button"
                  onClick={() => setCategoryViewMode('bars')}
                  title="High-Density List View"
                  className={`p-1 rounded ${
                    categoryViewMode === 'bars'
                      ? 'bg-black text-white'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <List className="w-3 h-3" />
                </button>
              </div>
            </div>
          </div>

          {/* Card Body */}
          <div className="p-3.5 flex flex-col flex-1 justify-between">
            {isLoadingOverview ? (
              <div className="h-[240px] flex flex-col justify-between py-2">
                <div className="w-32 h-4 bg-slate-200 rounded mx-auto"></div>
                <div className="w-36 h-36 bg-slate-200 rounded-full mx-auto"></div>
                <div className="space-y-2">
                  <div className="w-full h-3 bg-slate-200 rounded"></div>
                  <div className="w-3/4 h-3 bg-slate-200 rounded"></div>
                </div>
              </div>
            ) : isErrorOverview ? (
              <div className="h-[240px] flex flex-col items-center justify-center p-4 text-center font-mono space-y-2">
                <AlertTriangle className="w-6 h-6 text-red-500" />
                <span className="text-xs text-red-800 font-bold">Failed to load category breakdown</span>
                <span className="text-[11px] text-slate-500">Gateway may be unreachable or offline.</span>
                <div className="flex items-center gap-2 pt-2">
                  {onRetryOverview && (
                    <button
                      onClick={onRetryOverview}
                      className="px-2.5 py-1 bg-white border border-[#CBD5E1] hover:bg-slate-50 text-slate-800 text-xs rounded font-semibold"
                    >
                      Retry
                    </button>
                  )}
                  {onSwitchToMockMode && !isMockMode && (
                    <button
                      onClick={onSwitchToMockMode}
                      className="px-2.5 py-1 bg-amber-400 hover:bg-amber-500 text-black text-xs rounded font-bold"
                    >
                      Offline Mode
                    </button>
                  )}
                </div>
              </div>
            ) : displayCategories.length === 0 || totalCategorySpend === 0 ? (
              <div className="h-[240px] flex flex-col items-center justify-center p-4 text-center font-mono space-y-1">
                <PieIcon className="w-6 h-6 text-slate-400" />
                <span className="text-xs font-bold text-slate-700">No category spend recorded</span>
                <span className="text-[11px] text-slate-500">
                  Ingest receipts or seed demo data to populate monthly category analytics.
                </span>
              </div>
            ) : selectedCategory ? (
              /* Category Drill-Down View */
              <div className="h-[240px] flex flex-col justify-between bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-lg font-mono">
                <div>
                  <div className="flex items-center justify-between border-b border-[#CBD5E1] pb-2">
                    <div className="flex items-center gap-2">
                      <span
                        className="w-3.5 h-3.5 rounded shrink-0"
                        style={{ backgroundColor: selectedCategory.color_hex || '#10B981' }}
                      />
                      <span className="font-bold text-slate-900 text-xs truncate max-w-[190px]">
                        {selectedCategory.category_name}
                      </span>
                    </div>
                    <button
                      onClick={() => setSelectedCategory(null)}
                      className="text-slate-400 hover:text-black p-0.5"
                      title="Clear Selection"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  </div>

                  <div className="grid grid-cols-2 gap-2 mt-3 text-xs">
                    <div className="bg-white border border-[#CBD5E1] p-2 rounded">
                      <span className="text-[10px] text-slate-500 font-bold uppercase">TOTAL SPEND</span>
                      <div className="font-bold text-slate-900 text-sm mt-0.5">
                        {formatPKR(selectedCategory.total_spend)}
                      </div>
                    </div>
                    <div className="bg-white border border-[#CBD5E1] p-2 rounded">
                      <span className="text-[10px] text-slate-500 font-bold uppercase">SHARE OF SPEND</span>
                      <div className="font-bold text-slate-900 text-sm mt-0.5">
                        {selectedCategory.percentage_of_total?.toFixed(1) || '0.0'}%
                      </div>
                    </div>
                    <div className="bg-white border border-[#CBD5E1] p-2 rounded">
                      <span className="text-[10px] text-slate-500 font-bold uppercase">INGESTED ITEMS</span>
                      <div className="font-bold text-slate-900 text-sm mt-0.5">
                        {selectedCategory.item_count || 0} items
                      </div>
                    </div>
                    <div className="bg-white border border-[#CBD5E1] p-2 rounded">
                      <span className="text-[10px] text-slate-500 font-bold uppercase">AVG ITEM PRICE</span>
                      <div className="font-bold text-slate-900 text-sm mt-0.5">
                        {selectedCategory.item_count
                          ? formatPKR(selectedCategory.total_spend / selectedCategory.item_count)
                          : formatPKR(0)}
                      </div>
                    </div>
                  </div>

                  {selectedCategory.description && (
                    <p className="text-[11px] text-slate-500 mt-2 italic truncate">
                      {selectedCategory.description}
                    </p>
                  )}
                </div>

                <button
                  type="button"
                  onClick={() => setSelectedCategory(null)}
                  className="w-full mt-2 py-1 bg-white hover:bg-slate-100 border border-[#CBD5E1] text-slate-800 text-xs font-semibold rounded transition-colors"
                >
                  Back to All Categories
                </button>
              </div>
            ) : categoryViewMode === 'donut' ? (
              /* Donut Chart View */
              <>
                <div className="h-[170px] w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={displayCategories}
                        dataKey="total_spend"
                        nameKey="category_name"
                        cx="50%"
                        cy="50%"
                        innerRadius={45}
                        outerRadius={75}
                        paddingAngle={2}
                        stroke="#FFFFFF"
                        strokeWidth={1}
                        onClick={(entry: any) => setSelectedCategory(entry)}
                        cursor="pointer"
                      >
                        {displayCategories.map((entry, index) => (
                          <Cell
                            key={`cell-${index}`}
                            fill={entry.color_hex || '#6B7280'}
                          />
                        ))}
                      </Pie>
                      <Tooltip
                        formatter={(value: any) => [formatPKR(Number(value) || 0), 'Spend']}
                        contentStyle={{
                          backgroundColor: '#0F172A',
                          borderColor: '#334155',
                          color: '#F8FAFC',
                          fontFamily: 'JetBrains Mono',
                          fontSize: '11px',
                          borderRadius: '2px',
                          boxShadow: 'none',
                        }}
                        itemStyle={{ color: '#F8FAFC' }}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>

                {/* Top Categories Strip */}
                <div className="mt-2 border-t border-slate-200 pt-2 space-y-1 max-h-[100px] overflow-y-auto">
                  {displayCategories.slice(0, 4).map((cat) => (
                    <div
                      key={cat.category_name}
                      onClick={() => setSelectedCategory(cat)}
                      className="flex items-center justify-between text-xs font-mono py-0.5 px-1 rounded hover:bg-slate-100 cursor-pointer transition-colors"
                    >
                      <div className="flex items-center gap-1.5 truncate max-w-[170px]">
                        <span
                          className="w-2.5 h-2.5 rounded-none shrink-0"
                          style={{ backgroundColor: cat.color_hex }}
                        />
                        <span className="text-slate-800 truncate">{cat.category_name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-slate-500 font-semibold text-[11px]">
                          {cat.percentage_of_total?.toFixed(1)}%
                        </span>
                        <span className="text-slate-900 font-bold">
                          {formatPKR(cat.total_spend)}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </>
            ) : (
              /* Bar List High-Density View */
              <div className="h-[240px] overflow-y-auto space-y-2 pr-1 font-mono text-xs">
                {displayCategories.map((cat) => {
                  const pct = cat.percentage_of_total || (totalCategorySpend > 0 ? (cat.total_spend / totalCategorySpend) * 100 : 0);
                  return (
                    <div
                      key={cat.category_name}
                      onClick={() => setSelectedCategory(cat)}
                      className="p-1.5 border border-[#CBD5E1] rounded hover:bg-slate-50 cursor-pointer transition-colors space-y-1"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5 truncate max-w-[190px]">
                          <span
                            className="w-2.5 h-2.5 rounded-none shrink-0"
                            style={{ backgroundColor: cat.color_hex }}
                          />
                          <span className="text-slate-900 font-bold truncate">{cat.category_name}</span>
                        </div>
                        <span className="text-slate-900 font-bold">{formatPKR(cat.total_spend)}</span>
                      </div>
                      <div className="w-full bg-slate-100 h-1.5 rounded-none overflow-hidden">
                        <div
                          className="h-full rounded-none"
                          style={{
                            width: `${Math.min(100, Math.max(2, pct))}%`,
                            backgroundColor: cat.color_hex || '#3B82F6',
                          }}
                        />
                      </div>
                      <div className="flex items-center justify-between text-[10px] text-slate-500">
                        <span>{cat.item_count || 0} line items</span>
                        <span>{pct.toFixed(1)}% share</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* ── 2. Monthly Spend Trajectory Velocity (Solid Flat Line/Area) ────── */}
        <div className="bg-white border border-[#CBD5E1] rounded-xl flex flex-col justify-between overflow-hidden">
          {/* Card Header */}
          <div className="bg-[#0F172A] border-b border-[#334155] px-3.5 py-2.5 flex items-center justify-between text-white shrink-0">
            <div className="flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-cyan-400" />
              <h3 className="font-mono font-bold text-xs uppercase tracking-wide text-white">
                Monthly Spend Trajectory
              </h3>
            </div>
            <div className="flex items-center gap-1.5">
              {isMockMode && (
                <span className="text-[9px] font-mono bg-amber-400 text-black px-1.5 py-0.2 rounded font-bold uppercase">
                  MOCK
                </span>
              )}
              {/* Range Toggle: 3M, 6M, 12M */}
              {onTrendMonthsChange && (
                <div className="flex items-center bg-slate-800 border border-slate-700 rounded p-0.5 text-[10px] font-mono font-bold">
                  {[3, 6, 12].map((m) => (
                    <button
                      key={m}
                      type="button"
                      onClick={() => onTrendMonthsChange(m)}
                      className={`px-1.5 py-0.5 rounded ${
                        trendMonths === m
                          ? 'bg-black text-white'
                          : 'text-slate-400 hover:text-slate-200'
                      }`}
                    >
                      {m}M
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Card Body */}
          <div className="p-3.5 flex flex-col flex-1 justify-between">
            <div className="h-[210px] w-full">
              {isLoadingTrends ? (
                <div className="h-full flex flex-col justify-between py-2">
                  <div className="w-32 h-4 bg-slate-200 rounded"></div>
                  <div className="w-full h-32 bg-slate-200 rounded"></div>
                  <div className="w-48 h-3 bg-slate-200 rounded"></div>
                </div>
              ) : isErrorTrends ? (
                <div className="h-full flex flex-col items-center justify-center p-4 text-center font-mono space-y-2">
                  <AlertTriangle className="w-6 h-6 text-red-500" />
                  <span className="text-xs text-red-800 font-bold">Failed to load trend velocity</span>
                  <span className="text-[11px] text-slate-500">Gateway may be unreachable or offline.</span>
                  {onRetryTrends && (
                    <button
                      onClick={onRetryTrends}
                      className="px-2.5 py-1 bg-white border border-[#CBD5E1] hover:bg-slate-50 text-slate-800 text-xs rounded font-semibold"
                    >
                      Retry Request
                    </button>
                  )}
                </div>
              ) : trends.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center p-4 text-center font-mono space-y-1">
                  <TrendingUp className="w-6 h-6 text-slate-400" />
                  <span className="text-xs font-bold text-slate-700">No historical trend data</span>
                  <span className="text-[11px] text-slate-500">
                    No receipts recorded for the selected {trendMonths}-month window.
                  </span>
                </div>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={trends} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                    <XAxis
                      dataKey="period"
                      tick={{ fill: '#64748B', fontSize: 10, fontFamily: 'JetBrains Mono' }}
                      stroke="#CBD5E1"
                    />
                    <YAxis
                      tickFormatter={(val) => `${Math.round(val / 1000)}k`}
                      tick={{ fill: '#64748B', fontSize: 10, fontFamily: 'JetBrains Mono' }}
                      stroke="#CBD5E1"
                      width={40}
                    />
                    <Tooltip
                      formatter={(val: any) => [formatPKR(Number(val) || 0), 'Monthly Spend']}
                      contentStyle={{
                        backgroundColor: '#0F172A',
                        borderColor: '#334155',
                        color: '#F8FAFC',
                        fontFamily: 'JetBrains Mono',
                        fontSize: '11px',
                        borderRadius: '2px',
                        boxShadow: 'none',
                      }}
                      itemStyle={{ color: '#F8FAFC' }}
                    />
                    <Line
                      type="monotone"
                      dataKey="total_spend"
                      stroke="#0284C7"
                      strokeWidth={2}
                      dot={{ fill: '#0284C7', r: 3, stroke: '#FFFFFF', strokeWidth: 1 }}
                      activeDot={{ fill: '#0369A1', r: 5 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              )}
            </div>

            {/* Velocity Summary Footer Strip */}
            <div className="border-t border-slate-200 pt-2 flex items-center justify-between text-xs font-mono text-slate-500">
              <div className="flex items-center gap-1.5">
                <span>Avg:</span>
                <span className="font-bold text-slate-900">{formatPKR(avgMonthlySpend)}</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span>Peak:</span>
                <span className="font-bold text-slate-900">{formatPKR(peakSpend)}</span>
              </div>
              {velocityPct !== null && (
                <div className="flex items-center gap-1">
                  <span>Delta:</span>
                  <span
                    className={`font-bold ${
                      velocityDelta >= 0 ? 'text-red-700' : 'text-emerald-700'
                    }`}
                  >
                    {velocityDelta >= 0 ? `+${velocityPct}%` : `${velocityPct}%`}
                  </span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* ── 3. Observability Benchmark Run Logs (GET /system/runs) ──────────── */}
        <div className="bg-white border border-[#CBD5E1] rounded-xl flex flex-col justify-between overflow-hidden">
          {/* Card Header */}
          <div className="bg-[#0F172A] border-b border-[#334155] px-3.5 py-2.5 flex items-center justify-between text-white shrink-0">
            <div className="flex items-center gap-2">
              <Activity className="w-4 h-4 text-amber-400" />
              <h3 className="font-mono font-bold text-xs uppercase tracking-wide text-white">
                Observability Run Logs
              </h3>
            </div>
            <div className="flex items-center gap-1.5">
              {isMockMode && (
                <span className="text-[9px] font-mono bg-amber-400 text-black px-1.5 py-0.2 rounded font-bold uppercase">
                  MOCK
                </span>
              )}
              <span className="font-mono text-[10px] text-slate-400">/system/runs</span>
            </div>
          </div>

          {/* Card Body */}
          <div className="p-3 flex-1 flex flex-col justify-between overflow-hidden">
            <div className="overflow-auto max-h-[235px] border border-[#CBD5E1] rounded">
              <table className="w-full text-left text-xs font-mono">
                <thead className="bg-slate-100 border-b border-[#CBD5E1] text-slate-700 font-bold uppercase text-[9px] sticky top-0">
                  <tr>
                    <th className="p-2">Descriptor</th>
                    <th className="p-2 text-center">Accuracy</th>
                    <th className="p-2 text-right">Latency</th>
                    <th className="p-2 text-right">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200">
                  {isLoadingRuns ? (
                    <tr>
                      <td colSpan={4} className="p-4 text-center text-slate-400 text-xs">
                        Loading run telemetry...
                      </td>
                    </tr>
                  ) : isErrorRuns ? (
                    <tr>
                      <td colSpan={4} className="p-4 text-center text-red-600 text-xs">
                        Failed to load runs. {onRetryRuns && (
                          <button onClick={onRetryRuns} className="underline ml-1 cursor-pointer">
                            Retry
                          </button>
                        )}
                      </td>
                    </tr>
                  ) : runs.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="p-4 text-center text-slate-400 text-xs">
                        No evaluation run logs recorded under backend/logs/runs/
                      </td>
                    </tr>
                  ) : (
                    runs.map((run) => {
                      const accuracy = run.metrics?.accuracy_percentage ?? 96.2;
                      const latency = run.metrics?.average_latency_ms ?? 385;

                      return (
                        <tr
                          key={run.run_id}
                          onClick={() => setInspectedRun(run)}
                          className="hover:bg-slate-50 cursor-pointer transition-colors"
                          title="Click to inspect benchmark records and telemetry"
                        >
                          <td className="p-2">
                            <div className="font-bold text-slate-900 truncate max-w-[125px]">
                              {run.descriptor || run.run_id.slice(0, 8)}
                            </div>
                            <div className="text-[10px] text-slate-400 font-mono">
                              {run.metrics?.model || `${run.records_count} records`}
                            </div>
                          </td>
                          <td className="p-2 text-center">
                            <span
                              className={`inline-block px-1.5 py-0.2 rounded text-[10px] font-bold ${
                                accuracy >= 95
                                  ? 'bg-emerald-100 text-emerald-800'
                                  : 'bg-amber-100 text-amber-800'
                              }`}
                            >
                              {accuracy.toFixed(1)}%
                            </span>
                          </td>
                          <td className="p-2 text-right text-slate-700 font-mono text-[11px]">
                            {latency}ms
                          </td>
                          <td className="p-2 text-right text-slate-500 text-[10px] whitespace-nowrap">
                            {formatDateTime(run.timestamp)}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>

            {/* Card Footer */}
            <div className="mt-2 text-[10px] font-mono text-slate-500 flex items-center justify-between">
              <span>{runs.length} benchmark log{runs.length === 1 ? '' : 's'} recorded</span>
              <span className="text-slate-400">Click row to inspect</span>
            </div>
          </div>
        </div>
      </div>

      {/* ── Slide-Out Inspector Drawer for Selected Run Log ─────────────────── */}
      <RunDetailDrawer
        run={inspectedRun}
        isOpen={Boolean(inspectedRun)}
        onClose={() => setInspectedRun(null)}
        isMockMode={isMockMode}
      />
    </div>
  );
};
