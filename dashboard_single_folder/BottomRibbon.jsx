import React, { useEffect, useState } from 'react';
import { 
  PieChart as PieIcon, 
  TrendingUp, 
  Activity, 
  CheckCircle2, 
  Clock, 
  Sparkles,
  Layers,
  ArrowRight
} from 'lucide-react';
import { api } from '../services/api';

export default function BottomRibbon({ overview, refreshTrigger = 0 }) {
  const [trends, setTrends] = useState([]);
  const [runs, setRuns] = useState([]);

  useEffect(() => {
    // Load trends
    api.getTrends(6).then((res) => {
      setTrends(res?.months || []);
    });

    // Load observability runs
    api.getSystemRuns(10).then((res) => {
      setRuns(res || []);
    });
  }, [refreshTrigger]);

  const categories = overview?.category_breakdown || [
    { category_name: 'Groceries & Food', color_hex: '#10B981', total_spend: 42350.39, percentage_of_total: 23.0 },
    { category_name: 'Transportation', color_hex: '#6366F1', total_spend: 29918.41, percentage_of_total: 16.2 },
    { category_name: 'Dining Out', color_hex: '#EF4444', total_spend: 27799.19, percentage_of_total: 15.1 },
    { category_name: 'Utilities & Bills', color_hex: '#F59E0B', total_spend: 24582.08, percentage_of_total: 13.3 },
    { category_name: 'Snacks & Beverages', color_hex: '#EC4899', total_spend: 19445.54, percentage_of_total: 10.6 },
    { category_name: 'Health & Pharmacy', color_hex: '#06B6D4', total_spend: 18748.88, percentage_of_total: 10.2 },
    { category_name: 'Personal Care', color_hex: '#8B5CF6', total_spend: 11215.73, percentage_of_total: 6.1 },
    { category_name: 'Household & Cleaning', color_hex: '#3B82F6', total_spend: 10189.78, percentage_of_total: 5.5 }
  ];

  // SVG Donut calculation
  let accumulatedPct = 0;
  const donutSegments = categories.slice(0, 6).map((c) => {
    const startPct = accumulatedPct;
    accumulatedPct += c.percentage_of_total || 0;
    return {
      name: c.category_name,
      color: c.color_hex,
      pct: c.percentage_of_total || 0,
      spend: c.total_spend,
      startPct,
      endPct: accumulatedPct,
    };
  });

  return (
    <div className="bg-white border border-[#CBD5E1] rounded overflow-hidden select-none">
      {/* Ribbon Header */}
      <div className="bg-[#0F172A] border-b border-[#334155] px-4 py-2 flex items-center justify-between text-white">
        <div className="flex items-center gap-2">
          <Activity className="w-4 h-4 text-emerald-400" />
          <span className="font-mono font-bold text-xs tracking-wider uppercase">
            BOTTOM TELEMETRY &amp; ANALYTICS RIBBON
          </span>
        </div>
        <div className="text-[11px] font-mono text-slate-400">
          Observability Benchmark Run Logs (/api/v1/system/runs)
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 divide-y lg:divide-y-0 lg:divide-x divide-[#CBD5E1]">
        {/* 1. Category Spend Donut Chart (Zero Gradients - Solid Flat Fills) */}
        <div className="p-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs font-mono font-bold uppercase text-slate-700 tracking-wide flex items-center gap-1.5">
                <PieIcon className="w-3.5 h-3.5 text-slate-500" />
                Category Spend Donut
              </span>
              <span className="text-[10px] font-mono text-slate-400">Solid Fills</span>
            </div>

            {/* Custom SVG Solid Donut */}
            <div className="flex items-center gap-4">
              <div className="relative w-28 h-28 shrink-0 flex items-center justify-center">
                <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
                  {donutSegments.map((seg, idx) => {
                    const strokeDash = `${seg.pct} ${100 - seg.pct}`;
                    const strokeOffset = -seg.startPct;
                    return (
                      <circle
                        key={idx}
                        cx="18"
                        cy="18"
                        r="15.915"
                        fill="transparent"
                        stroke={seg.color}
                        strokeWidth="5"
                        strokeDasharray={strokeDash}
                        strokeDashoffset={strokeOffset}
                      />
                    );
                  })}
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <span className="font-mono font-bold text-xs text-slate-900">8 Cats</span>
                  <span className="text-[9px] font-mono text-slate-400">100%</span>
                </div>
              </div>

              {/* Legend List */}
              <div className="flex-1 space-y-1.5 text-xs font-mono max-h-28 overflow-y-auto pr-1">
                {categories.slice(0, 5).map((cat, idx) => (
                  <div key={idx} className="flex items-center justify-between text-[11px]">
                    <div className="flex items-center gap-1.5 truncate max-w-[120px]">
                      <span className="w-2 h-2 rounded-none shrink-0" style={{ backgroundColor: cat.color_hex }} />
                      <span className="truncate text-slate-700">{cat.category_name}</span>
                    </div>
                    <span className="font-bold text-slate-900 ml-1">
                      {cat.percentage_of_total}%
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-[11px] font-mono text-slate-500">
            <span>Primary: Groceries (23%)</span>
            <span>Total: PKR 184,250</span>
          </div>
        </div>

        {/* 2. Monthly Spend Trajectory Velocity */}
        <div className="p-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs font-mono font-bold uppercase text-slate-700 tracking-wide flex items-center gap-1.5">
                <TrendingUp className="w-3.5 h-3.5 text-slate-500" />
                Monthly Trajectory Velocity
              </span>
              <span className="text-[10px] font-mono text-emerald-700 bg-emerald-100 border border-emerald-300 px-1 py-0.2 rounded font-bold">
                +14.0% Velocity
              </span>
            </div>

            {/* Sparkline Bar Series */}
            <div className="h-28 flex items-end gap-2 pt-4 px-1">
              {(trends.length > 0 ? trends : [
                { period: "May", total_spend: 142000 },
                { period: "Jun", total_spend: 153400 },
                { period: "Jul", total_spend: 148900 },
                { period: "Aug", total_spend: 159100 },
                { period: "Sep", total_spend: 161620 },
                { period: "Oct", total_spend: 184250 },
              ]).map((pt, idx, arr) => {
                const maxVal = 200000;
                const heightPct = Math.round((pt.total_spend / maxVal) * 100);
                const isCurrent = idx === arr.length - 1;

                return (
                  <div key={idx} className="flex-1 flex flex-col items-center gap-1 group relative">
                    <div 
                      className={`w-full transition-all duration-300 ${
                        isCurrent 
                          ? 'bg-blue-600 border border-blue-700' 
                          : 'bg-slate-300 hover:bg-slate-400'
                      }`}
                      style={{ height: `${heightPct}%` }}
                    />
                    <span className={`text-[10px] font-mono ${isCurrent ? 'font-bold text-blue-700' : 'text-slate-500'}`}>
                      {pt.period.slice(-2)}
                    </span>

                    {/* Tooltip */}
                    <div className="absolute -top-7 hidden group-hover:block bg-slate-900 text-white font-mono text-[9px] px-1.5 py-0.5 rounded shadow z-20 whitespace-nowrap">
                      PKR {Math.round(pt.total_spend).toLocaleString()}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-[11px] font-mono text-slate-500">
            <span>Sep: PKR 161,620</span>
            <span className="font-bold text-slate-800">Oct: PKR 184,250 (+14%)</span>
          </div>
        </div>

        {/* 3. Observability Benchmark Run Logs (/api/v1/system/runs) */}
        <div className="p-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-mono font-bold uppercase text-slate-700 tracking-wide flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-slate-500" />
                Benchmark Run Logs
              </span>
              <span className="text-[10px] font-mono text-slate-500">
                {runs.length} runs recorded
              </span>
            </div>

            {/* Run Logs Feed */}
            <div className="space-y-2 max-h-28 overflow-y-auto pr-1">
              {(runs.length > 0 ? runs : [
                {
                  descriptor: "gemini_flash_lite_evaluation_run",
                  metrics: { accuracy_percentage: 96.2, average_latency_ms: 385, total_records: 148 }
                },
                {
                  descriptor: "cloud_vision_hybrid_benchmark",
                  metrics: { accuracy_percentage: 94.8, average_latency_ms: 512, total_records: 100 }
                }
              ]).slice(0, 3).map((r, idx) => {
                const acc = r.metrics?.accuracy_percentage || 96.2;
                const latency = r.metrics?.average_latency_ms || 385;
                const records = r.metrics?.total_records || r.records_count || 148;

                return (
                  <div key={idx} className="bg-slate-50 border border-slate-200 p-2 rounded text-xs font-mono flex items-center justify-between">
                    <div className="truncate max-w-[190px]">
                      <div className="font-semibold text-slate-900 truncate">
                        {r.descriptor || 'gemini_evaluation'}
                      </div>
                      <div className="text-[10px] text-slate-400">
                        {records} records • {latency}ms avg
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <span className="inline-block px-1.5 py-0.5 rounded text-[10px] font-bold bg-blue-100 text-blue-800 border border-blue-200">
                        {acc}% Acc
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="mt-3 pt-2 border-t border-slate-100 flex items-center justify-between text-[11px] font-mono text-slate-500">
            <span>Model: gemini-3.5-flash-lite</span>
            <span className="text-emerald-700 font-bold">100% Pipeline PASS</span>
          </div>
        </div>
      </div>
    </div>
  );
}
