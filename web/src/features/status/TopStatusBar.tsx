import React, { useState } from 'react';
import {
  Sparkles,
  Eye,
  Database,
  Cpu,
  RefreshCw,
  Trash2,
  Upload,
  Download,
  HelpCircle,
  LogOut,
  WifiOff,
  CheckCircle2,
  AlertTriangle,
} from 'lucide-react';
import { HealthResponse } from '../../types';
import { useConsoleStore } from '../../store/useConsoleStore';

export interface TopStatusBarProps {
  health?: HealthResponse;
  isHealthLoading: boolean;
  onSeedDemo: () => Promise<void>;
  onResetLedger: () => Promise<void>;
  isSeeding: boolean;
  isResetting: boolean;
  userEmail?: string;
  onLogout: () => void;
  isMockMode?: boolean;
  onEnterDevMockMode?: () => void;
  onExportCsv?: () => void;
}

export const TopStatusBar: React.FC<TopStatusBarProps> = ({
  health,
  isHealthLoading,
  onSeedDemo,
  onResetLedger,
  isSeeding,
  isResetting,
  userEmail,
  onLogout,
  isMockMode = false,
  onEnterDevMockMode,
  onExportCsv,
}) => {
  const { toggleShortcutsPanel, toggleUploadDrawer } = useConsoleStore();
  const [resetConfirmStep, setResetConfirmStep] = useState(false);

  // Compute operational health
  const engines = health?.engines;
  const isCloudVisionOk = engines?.cloud_vision ? engines.cloud_vision.startsWith('ok') : false;
  const isGeminiOk = engines?.gemini ? engines.gemini.startsWith('ok') : false;
  const isDbOk = Boolean(engines?.database && engines.database !== 'unavailable' && engines.database !== 'error');
  const isTesseractOk = engines?.tesseract ? engines.tesseract.startsWith('ok') : false;
  const isEasyOcrOk = engines?.easyocr ? engines.easyocr.startsWith('ok') : false;

  const allOperational = isCloudVisionOk && isGeminiOk && isDbOk;
  const quotaMatch = engines?.cloud_vision?.match(/quota_remaining=(\d+)/);
  const quotaRemaining = quotaMatch ? parseInt(quotaMatch[1], 10) : null;

  // Handle two-step reset confirmation (Inline, NO modal popup!)
  const handleResetClick = async () => {
    if (!resetConfirmStep) {
      setResetConfirmStep(true);
      return;
    }
    setResetConfirmStep(false);
    await onResetLedger();
  };

  const handleCancelReset = () => {
    setResetConfirmStep(false);
  };

  return (
    <header className="bg-white border-b border-[#CBD5E1] text-slate-900 px-5 py-3 select-none">
      <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-3">
        {/* Left: Branding & Workspace title */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-black text-white rounded-lg flex items-center justify-center font-mono font-bold text-xs tracking-wider shrink-0">
            RL
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-mono font-bold text-sm tracking-wider uppercase text-slate-900">
                RECEIPTLEDGER DESKTOP CONSOLE
              </h1>
              <span className="font-mono text-[10px] font-semibold bg-[#F1F5F9] text-slate-700 border border-[#CBD5E1] px-1.5 py-0.5 rounded">
                1280px+ Fixed-Fluid
              </span>
            </div>
            <div className="text-[11px] font-mono text-slate-500 flex items-center gap-2 mt-0.5">
              <span>Scope: Admin, Audit &amp; Triage</span>
              <span>•</span>
              <span className="truncate">Gateway: http://localhost:8000/api/v1</span>
            </div>
          </div>
        </div>

        {/* Center: System Status & Engine Chips driven by GET /health */}
        <div className="flex items-center flex-wrap gap-2 text-xs font-mono bg-[#F8FAFC] border border-[#CBD5E1] px-3 py-1.5 rounded-xl">
          <span className="text-slate-500 font-semibold tracking-wide text-[11px]">SYSTEM:</span>
          {isMockMode ? (
            <span className="flex items-center gap-1.5 bg-amber-50 text-amber-900 border border-amber-300 font-semibold px-2 py-0.5 rounded text-[11px]">
              <WifiOff className="w-3 h-3 text-amber-700" />
              OFFLINE DEMO METRICS (MOCK)
            </span>
          ) : isHealthLoading ? (
            <span className="flex items-center gap-1.5 text-slate-500 text-[11px]">
              <span className="w-2 h-2 rounded-full bg-slate-400 animate-pulse inline-block" />
              CHECKING SYSTEM...
            </span>
          ) : allOperational ? (
            <span className="flex items-center gap-1.5 text-emerald-800 bg-emerald-50 border border-emerald-300 px-2 py-0.5 rounded font-semibold text-[11px]">
              <CheckCircle2 className="w-3 h-3 text-emerald-600 inline-block" />
              ALL ENGINES OPERATIONAL
            </span>
          ) : (
            <span className="flex items-center gap-1.5 text-amber-900 bg-amber-50 border border-amber-300 px-2 py-0.5 rounded font-semibold text-[11px]">
              <AlertTriangle className="w-3 h-3 text-amber-600 inline-block" />
              ENGINES DEGRADED
            </span>
          )}

          {!isMockMode && onEnterDevMockMode && !allOperational && (
            <button
              type="button"
              onClick={onEnterDevMockMode}
              title="Switch to Offline Dev Mode with mock fixtures"
              className="flex items-center gap-1 font-mono text-[11px] font-bold bg-amber-100 hover:bg-amber-200 text-amber-900 border border-amber-300 px-2 py-0.5 rounded transition-colors cursor-pointer"
            >
              <WifiOff className="w-3 h-3 text-amber-700" />
              <span>Offline Dev Mode</span>
            </button>
          )}

          <span className="text-slate-300">|</span>

          {/* Engine Chips */}
          <div className="flex items-center gap-1.5 text-[11px] text-slate-700 flex-wrap">
            <span
              className={`flex items-center gap-1 px-1.5 py-0.5 rounded border ${
                isGeminiOk
                  ? 'bg-white text-slate-900 border-[#CBD5E1]'
                  : 'bg-amber-50 text-amber-900 border-amber-300'
              }`}
              title={engines?.gemini || 'Gemini'}
            >
              <Sparkles className="w-3 h-3 text-amber-600" />
              GEMINI AI
            </span>

            <span
              className={`flex items-center gap-1 px-1.5 py-0.5 rounded border ${
                isCloudVisionOk
                  ? 'bg-white text-slate-900 border-[#CBD5E1]'
                  : 'bg-amber-50 text-amber-900 border-amber-300'
              }`}
              title={engines?.cloud_vision || 'Cloud Vision'}
            >
              <Eye className="w-3 h-3 text-blue-600" />
              CLOUD VISION
              {quotaRemaining !== null && (
                <span
                  className={`font-semibold ${
                    quotaRemaining < 100 ? 'text-amber-700 font-bold' : 'text-slate-500 font-normal'
                  }`}
                >
                  ({quotaRemaining} quota)
                </span>
              )}
            </span>

            <span
              className={`flex items-center gap-1 px-1.5 py-0.5 rounded border ${
                isDbOk
                  ? 'bg-white text-slate-900 border-[#CBD5E1]'
                  : 'bg-red-50 text-red-900 border-red-300'
              }`}
              title={`Database: ${engines?.database || 'supabase'}`}
            >
              <Database className="w-3 h-3 text-emerald-600" />
              {engines?.database?.includes('supabase') ? 'SUPABASE' : 'DATABASE'}
            </span>

            <span
              className={`flex items-center gap-1 px-1.5 py-0.5 rounded border ${
                isTesseractOk
                  ? 'bg-white text-slate-900 border-[#CBD5E1]'
                  : 'bg-[#F1F5F9] text-slate-400 border-slate-200'
              }`}
              title={`Tesseract: ${engines?.tesseract || 'n/a'}`}
            >
              <Cpu className="w-3 h-3 text-slate-500" />
              TESSERACT
            </span>

            <span
              className={`flex items-center gap-1 px-1.5 py-0.5 rounded border ${
                isEasyOcrOk
                  ? 'bg-white text-slate-900 border-[#CBD5E1]'
                  : 'bg-[#F1F5F9] text-slate-400 border-slate-200'
              }`}
              title={`EasyOCR: ${engines?.easyocr || 'n/a'}`}
            >
              <Cpu className="w-3 h-3 text-slate-500" />
              EASYOCR
            </span>
          </div>
        </div>

        {/* Right: Tactile Testing & Action Controls */}
        <div className="flex items-center gap-2 flex-wrap">
          {/* Seed Demo / Reload Mock Queue Button */}
          <button
            type="button"
            onClick={onSeedDemo}
            disabled={isSeeding}
            title={
              isMockMode
                ? 'Reload clearly labelled mock review-queue items and receipts'
                : 'POST /api/v1/dashboard/seed-demo - Seeds 148 Pakistani receipts'
            }
            className="flex items-center gap-1.5 bg-black hover:bg-slate-800 disabled:opacity-50 text-white font-mono text-xs font-semibold px-3 py-1.5 rounded-lg border border-black transition-colors cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isSeeding ? 'animate-spin' : ''}`} />
            <span>{isMockMode ? 'Reload Mock Queue' : 'Seed Demo (148)'}</span>
          </button>

          {/* Inline Two-Step Reset Ledger Button (Rule: Confirm inline, never use modal!) */}
          {!resetConfirmStep ? (
            <button
              type="button"
              onClick={() => setResetConfirmStep(true)}
              disabled={isResetting}
              title="POST /api/v1/dashboard/reset - Test zero-data states"
              className="flex items-center gap-1.5 bg-white hover:bg-red-50 hover:text-red-700 hover:border-red-300 text-slate-700 font-mono text-xs px-2.5 py-1.5 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
            >
              <Trash2 className="w-3.5 h-3.5 text-slate-500" />
              <span>Reset Ledger</span>
            </button>
          ) : (
            <div className="flex items-center gap-1 bg-red-50 border border-red-300 p-0.5 rounded-lg font-mono text-xs">
              <button
                type="button"
                onClick={handleResetClick}
                disabled={isResetting}
                className="bg-red-600 hover:bg-red-700 text-white font-bold px-2 py-1 rounded transition-colors cursor-pointer"
              >
                Confirm Reset?
              </button>
              <button
                type="button"
                onClick={handleCancelReset}
                className="text-slate-600 hover:text-black px-2 py-1 transition-colors cursor-pointer"
              >
                Cancel
              </button>
            </div>
          )}

          {/* Export CSV Ledger Button */}
          {onExportCsv && (
            <button
              type="button"
              onClick={onExportCsv}
              title={
                isMockMode
                  ? 'Download verified sample receipt ledger as CSV'
                  : 'GET /api/v1/analytics/export?format=csv - Export full ledger'
              }
              className="flex items-center gap-1.5 bg-white hover:bg-slate-50 text-slate-800 font-mono text-xs font-semibold px-2.5 py-1.5 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
            >
              <Download className="w-3.5 h-3.5 text-slate-500" />
              <span>Export CSV</span>
            </button>
          )}

          {/* Upload Receipt Button */}
          <button
            type="button"
            onClick={toggleUploadDrawer}
            title="Upload and ingest receipt image"
            className="flex items-center gap-1.5 bg-white hover:bg-slate-50 text-slate-800 font-mono text-xs font-semibold px-3 py-1.5 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
          >
            <Upload className="w-3.5 h-3.5 text-slate-500" />
            <span>Upload Receipt</span>
          </button>

          {/* Keyboard Shortcuts Help Button */}
          <button
            type="button"
            onClick={toggleShortcutsPanel}
            title="Keyboard shortcuts cheat sheet (key '?')"
            className="flex items-center justify-center w-8 h-8 bg-white hover:bg-slate-50 text-slate-700 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
          >
            <HelpCircle className="w-4 h-4 text-slate-500" />
          </button>

          {/* User Profile & Logout */}
          <div className="flex items-center gap-1.5 text-xs font-mono bg-[#F8FAFC] text-slate-700 border border-[#CBD5E1] px-2.5 py-1 rounded-lg">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
            <span className="text-slate-700 truncate max-w-[140px] font-medium" title={userEmail}>
              {userEmail || 'operator'}
            </span>
            <button
              type="button"
              onClick={onLogout}
              title="Sign Out"
              className="text-slate-400 hover:text-red-600 transition-colors ml-1 cursor-pointer"
            >
              <LogOut className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};
