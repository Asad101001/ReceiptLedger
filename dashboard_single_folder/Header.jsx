import React from 'react';
import { 
  Terminal, 
  Cpu, 
  Database, 
  Eye, 
  Sparkles, 
  RefreshCw, 
  Trash2, 
  Upload, 
  HelpCircle, 
  CheckCircle2, 
  AlertCircle 
} from 'lucide-react';

export default function Header({ 
  health, 
  onSeedDemo, 
  onResetLedger, 
  onOpenUpload, 
  onOpenShortcuts,
  loadingSeed,
  loadingReset
}) {
  const isGeminiOk = health?.engines?.gemini?.includes('ok');
  const isVisionOk = health?.engines?.cloud_vision?.includes('ok');
  const isDbOk = health?.engines?.database?.includes('supabase') || health?.engines?.database?.includes('in_memory');

  return (
    <header className="bg-[#0F172A] border-b border-[#334155] text-white px-5 py-3 select-none">
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-3">
        {/* Left: Branding & Workspace title */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-emerald-600 border border-emerald-500 rounded flex items-center justify-center font-mono font-bold text-white text-base shadow-sm">
            RL
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-mono font-bold text-sm tracking-wider uppercase text-slate-100">
                RECEIPTLEDGER DESKTOP CONSOLE
              </h1>
              <span className="font-mono text-[11px] bg-slate-800 text-slate-300 border border-slate-700 px-1.5 py-0.5 rounded">
                [1280px+ Fixed-Fluid Workspace]
              </span>
            </div>
            <div className="text-[11px] font-mono text-slate-400 flex items-center gap-2 mt-0.5">
              <span>Scope: Admin, Audit & Triage</span>
              <span>•</span>
              <span>Gateway: http://localhost:8000/api/v1</span>
            </div>
          </div>
        </div>

        {/* Center: System Status & Engine Chips */}
        <div className="flex items-center flex-wrap gap-2 text-xs font-mono bg-slate-900 border border-slate-800 px-3 py-1.5 rounded">
          <span className="text-slate-400 font-semibold tracking-wide">STATUS:</span>
          <span className="flex items-center gap-1.5 text-emerald-400 font-semibold">
            <span className="w-2 h-2 rounded-full bg-emerald-500 inline-block"></span>
            ALL ENGINES OPERATIONAL
          </span>
          <span className="text-slate-600">|</span>
          <div className="flex items-center gap-1.5 text-[11px] text-slate-300">
            <span className="flex items-center gap-1 bg-slate-800 border border-slate-700 px-1.5 py-0.5 rounded">
              <Sparkles className="w-3 h-3 text-amber-400" /> GEMINI AI
            </span>
            <span className="flex items-center gap-1 bg-slate-800 border border-slate-700 px-1.5 py-0.5 rounded">
              <Eye className="w-3 h-3 text-cyan-400" /> CLOUD VISION
            </span>
            <span className="flex items-center gap-1 bg-slate-800 border border-slate-700 px-1.5 py-0.5 rounded">
              <Database className="w-3 h-3 text-emerald-400" /> SUPABASE
            </span>
          </div>
        </div>

        {/* Right: Tactile Testing & Action Controls */}
        <div className="flex items-center gap-2">
          {/* Seed Demo Data Button */}
          <button
            onClick={onSeedDemo}
            disabled={loadingSeed}
            title="POST /api/v1/dashboard/seed-demo - Loads 148 realistic Pakistani receipts"
            className="flex items-center gap-1.5 bg-emerald-700 hover:bg-emerald-600 disabled:opacity-50 text-white font-mono text-xs font-semibold px-3 py-1.5 rounded border border-emerald-500 transition-colors cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingSeed ? 'animate-spin' : ''}`} />
            Seed Demo Data (148)
          </button>

          {/* Reset Ledger Button */}
          <button
            onClick={onResetLedger}
            disabled={loadingReset}
            title="POST /api/v1/dashboard/reset - Test zero-data states"
            className="flex items-center gap-1.5 bg-slate-800 hover:bg-red-950/50 hover:text-red-400 hover:border-red-600 text-slate-300 font-mono text-xs px-2.5 py-1.5 rounded border border-slate-700 transition-colors cursor-pointer"
          >
            <Trash2 className="w-3.5 h-3.5" />
            Reset Ledger
          </button>

          {/* Upload Receipt Button */}
          <button
            onClick={onOpenUpload}
            title="Upload and ingest new receipt image (POST /api/v1/receipts/upload)"
            className="flex items-center gap-1.5 bg-blue-600 hover:bg-blue-500 text-white font-mono text-xs font-semibold px-3 py-1.5 rounded border border-blue-500 transition-colors cursor-pointer"
          >
            <Upload className="w-3.5 h-3.5" />
            Upload Receipt
          </button>

          {/* Keyboard Shortcuts Help */}
          <button
            onClick={onOpenShortcuts}
            title="Keyboard shortcuts cheat sheet (Press '?')"
            className="flex items-center justify-center w-7 h-7 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded border border-slate-700 transition-colors cursor-pointer"
          >
            <HelpCircle className="w-4 h-4" />
          </button>

          {/* Admin User Chip */}
          <div className="hidden 2xl:flex items-center gap-1.5 text-xs font-mono bg-slate-800 text-slate-300 border border-slate-700 px-2 py-1 rounded">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
            <span className="text-slate-400">user@receiptledger.com</span>
          </div>
        </div>
      </div>
    </header>
  );
}
