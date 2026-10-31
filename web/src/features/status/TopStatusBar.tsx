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
  Settings,
  X,
  Server,
} from 'lucide-react';
import { HealthResponse } from '../../types';
import { useConsoleStore } from '../../store/useConsoleStore';
import { getApiBaseUrl, setApiBaseUrl } from '../../api/client';

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

  // Gateway URL Configuration Modal State
  const [isGatewayModalOpen, setIsGatewayModalOpen] = useState(false);
  const [customGatewayUrl, setCustomGatewayUrl] = useState(getApiBaseUrl());
  const [testResult, setTestResult] = useState<{ ok: boolean; message: string } | null>(null);
  const [isTestingGateway, setIsTestingGateway] = useState(false);

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

  // Test Gateway Connection
  const handleTestGateway = async () => {
    setIsTestingGateway(true);
    setTestResult(null);
    try {
      const cleanUrl = customGatewayUrl.trim().replace(/\/+$/, '');
      const testReq = await fetch(`${cleanUrl}/health`, { credentials: 'omit' });
      if (testReq.ok) {
        const data = await testReq.json();
        setTestResult({
          ok: true,
          message: `Connected successfully! (Status: ${data.status || 'healthy'})`,
        });
      } else {
        setTestResult({
          ok: false,
          message: `Gateway returned HTTP status ${testReq.status}`,
        });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setTestResult({
        ok: false,
        message: `Failed to connect: ${msg}`,
      });
    } finally {
      setIsTestingGateway(false);
    }
  };

  const handleSaveGateway = () => {
    const cleanUrl = customGatewayUrl.trim().replace(/\/+$/, '');
    setApiBaseUrl(cleanUrl);
    setIsGatewayModalOpen(false);
    window.location.reload();
  };

  const handleResetGatewayToDefault = () => {
    setApiBaseUrl(null);
    setCustomGatewayUrl(getApiBaseUrl());
    window.location.reload();
  };

  const currentGateway = getApiBaseUrl();

  return (
    <>
      <header className="bg-white border-b border-[#CBD5E1] text-slate-900 px-3 sm:px-5 py-2.5 sm:py-3 select-none">
        <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-3">
          {/* Left: Branding & Workspace title */}
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-black text-white rounded-lg flex items-center justify-center font-mono font-bold text-xs tracking-wider shrink-0">
              RL
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h1 className="font-mono font-bold text-xs sm:text-sm tracking-wider uppercase text-slate-900">
                  RECEIPTLEDGER OPERATIONS CONSOLE
                </h1>
                <span className="font-mono text-[9px] sm:text-[10px] font-semibold bg-[#F1F5F9] text-slate-700 border border-[#CBD5E1] px-1.5 py-0.5 rounded">
                  Responsive
                </span>
              </div>
              <div className="text-[10px] sm:text-[11px] font-mono text-slate-500 flex items-center gap-2 mt-0.5 flex-wrap">
                <span>Admin, Audit &amp; Triage</span>
                <span>•</span>
                <button
                  type="button"
                  onClick={() => setIsGatewayModalOpen(true)}
                  className="inline-flex items-center gap-1 text-slate-700 hover:text-black font-semibold underline decoration-slate-300 hover:decoration-black cursor-pointer truncate max-w-[260px] sm:max-w-none"
                  title="Configure backend gateway URL"
                >
                  <Server className="w-3 h-3 text-emerald-600 inline shrink-0" />
                  <span className="truncate">{currentGateway}</span>
                  <Settings className="w-3 h-3 text-slate-400 inline shrink-0 ml-0.5" />
                </button>
              </div>
            </div>
          </div>

          {/* Center: System Status & Engine Chips driven by GET /health */}
          <div className="flex items-center flex-wrap gap-2 text-xs font-mono bg-[#F8FAFC] border border-[#CBD5E1] px-2.5 sm:px-3 py-1.5 rounded-xl">
            <span className="text-slate-500 font-semibold tracking-wide text-[10px] sm:text-[11px]">STATUS:</span>
            {isMockMode ? (
              <span className="flex items-center gap-1.5 bg-amber-50 text-amber-900 border border-amber-300 font-semibold px-2 py-0.5 rounded text-[10px] sm:text-[11px]">
                <WifiOff className="w-3 h-3 text-amber-700" />
                OFFLINE DEMO METRICS (MOCK)
              </span>
            ) : isHealthLoading ? (
              <span className="flex items-center gap-1.5 text-slate-500 text-[10px] sm:text-[11px]">
                <span className="w-2 h-2 rounded-full bg-slate-400 animate-pulse inline-block" />
                CHECKING SYSTEM...
              </span>
            ) : allOperational ? (
              <span className="flex items-center gap-1.5 text-emerald-800 bg-emerald-50 border border-emerald-300 px-2 py-0.5 rounded font-semibold text-[10px] sm:text-[11px]">
                <CheckCircle2 className="w-3 h-3 text-emerald-600 inline-block" />
                ALL ENGINES OPERATIONAL
              </span>
            ) : (
              <span className="flex items-center gap-1.5 text-amber-900 bg-amber-50 border border-amber-300 px-2 py-0.5 rounded font-semibold text-[10px] sm:text-[11px]">
                <AlertTriangle className="w-3 h-3 text-amber-600 inline-block" />
                ENGINES DEGRADED
              </span>
            )}

            {!isMockMode && onEnterDevMockMode && !allOperational && (
              <button
                type="button"
                onClick={onEnterDevMockMode}
                title="Switch to Offline Dev Mode with mock fixtures"
                className="flex items-center gap-1 font-mono text-[10px] sm:text-[11px] font-bold bg-amber-100 hover:bg-amber-200 text-amber-900 border border-amber-300 px-2 py-0.5 rounded transition-colors cursor-pointer"
              >
                <WifiOff className="w-3 h-3 text-amber-700" />
                <span>Offline Dev Mode</span>
              </button>
            )}

            <span className="hidden sm:inline text-slate-300">|</span>

            {/* Engine Chips */}
            <div className="flex items-center gap-1.5 text-[10px] sm:text-[11px] text-slate-700 flex-wrap">
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
                    ({quotaRemaining})
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
                className={`hidden md:flex items-center gap-1 px-1.5 py-0.5 rounded border ${
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
                className={`hidden md:flex items-center gap-1 px-1.5 py-0.5 rounded border ${
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
            {/* Seed Demo Button */}
            <button
              type="button"
              onClick={onSeedDemo}
              disabled={isSeeding}
              title={
                isMockMode
                  ? 'Reload clearly labelled mock review-queue items and receipts'
                  : 'POST /api/v1/dashboard/seed-demo - Seeds 148 Pakistani receipts'
              }
              className="flex items-center gap-1.5 bg-black hover:bg-slate-800 disabled:opacity-50 text-white font-mono text-xs font-semibold px-2.5 sm:px-3 py-1.5 rounded-lg border border-black transition-colors cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isSeeding ? 'animate-spin' : ''}`} />
              <span className="hidden sm:inline">{isMockMode ? 'Reload Mock' : 'Seed Demo (148)'}</span>
              <span className="sm:hidden">{isMockMode ? 'Reload' : 'Seed'}</span>
            </button>

            {/* Inline Two-Step Reset Ledger Button */}
            {!resetConfirmStep ? (
              <button
                type="button"
                onClick={() => setResetConfirmStep(true)}
                disabled={isResetting}
                title="POST /api/v1/dashboard/reset - Test zero-data states"
                className="flex items-center gap-1.5 bg-white hover:bg-red-50 hover:text-red-700 hover:border-red-300 text-slate-700 font-mono text-xs px-2 sm:px-2.5 py-1.5 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
              >
                <Trash2 className="w-3.5 h-3.5 text-slate-500" />
                <span className="hidden sm:inline">Reset</span>
              </button>
            ) : (
              <div className="flex items-center gap-1 bg-red-50 border border-red-300 p-0.5 rounded-lg font-mono text-xs">
                <button
                  type="button"
                  onClick={handleResetClick}
                  disabled={isResetting}
                  className="bg-red-600 hover:bg-red-700 text-white font-bold px-2 py-1 rounded transition-colors cursor-pointer text-[11px]"
                >
                  Confirm?
                </button>
                <button
                  type="button"
                  onClick={handleCancelReset}
                  className="text-slate-600 hover:text-black px-1.5 py-1 transition-colors cursor-pointer text-[11px]"
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
                title="Export full ledger as CSV"
                className="flex items-center gap-1 bg-white hover:bg-slate-50 text-slate-800 font-mono text-xs font-semibold px-2 sm:px-2.5 py-1.5 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
              >
                <Download className="w-3.5 h-3.5 text-slate-500" />
                <span className="hidden sm:inline">Export CSV</span>
              </button>
            )}

            {/* Upload Receipt Button */}
            <button
              type="button"
              onClick={toggleUploadDrawer}
              title="Upload and ingest receipt image"
              className="flex items-center gap-1.5 bg-white hover:bg-slate-50 text-slate-800 font-mono text-xs font-semibold px-2.5 sm:px-3 py-1.5 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
            >
              <Upload className="w-3.5 h-3.5 text-slate-500" />
              <span className="hidden sm:inline">Upload</span>
            </button>

            {/* Gateway Settings Button */}
            <button
              type="button"
              onClick={() => setIsGatewayModalOpen(true)}
              title="Configure API Gateway Endpoint"
              className="flex items-center justify-center w-8 h-8 bg-white hover:bg-slate-50 text-slate-700 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
            >
              <Settings className="w-3.5 h-3.5 text-slate-600" />
            </button>

            {/* Shortcuts Help Button */}
            <button
              type="button"
              onClick={toggleShortcutsPanel}
              title="Keyboard shortcuts cheat sheet (key '?')"
              className="hidden sm:flex items-center justify-center w-8 h-8 bg-white hover:bg-slate-50 text-slate-700 rounded-lg border border-[#CBD5E1] transition-colors cursor-pointer"
            >
              <HelpCircle className="w-4 h-4 text-slate-500" />
            </button>

            {/* User Profile & Logout */}
            <div className="flex items-center gap-1 text-xs font-mono bg-[#F8FAFC] text-slate-700 border border-[#CBD5E1] px-2 py-1 rounded-lg">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 shrink-0"></span>
              <span className="hidden sm:inline text-slate-700 truncate max-w-[120px] font-medium" title={userEmail}>
                {userEmail || 'operator'}
              </span>
              <button
                type="button"
                onClick={onLogout}
                title="Sign Out"
                className="text-slate-400 hover:text-red-600 transition-colors ml-0.5 cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* ── API Gateway Configuration Modal ───────────────────────────────── */}
      {isGatewayModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="API Gateway Settings"
          className="fixed inset-0 z-50 overflow-hidden flex items-center justify-center p-4 select-none"
        >
          {/* Backdrop */}
          <div
            onClick={() => setIsGatewayModalOpen(false)}
            className="fixed inset-0 bg-slate-950/70 transition-opacity"
            aria-hidden="true"
          />

          {/* Modal Panel */}
          <div className="relative w-full max-w-lg bg-white border border-[#CBD5E1] rounded-2xl shadow-2xl z-10 overflow-hidden">
            <div className="bg-[#0F172A] border-b border-[#334155] text-white p-4 flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="p-1.5 bg-slate-800 border border-slate-700 rounded-lg">
                  <Server className="w-4 h-4 text-emerald-400" />
                </div>
                <div>
                  <h3 className="font-mono font-bold text-xs uppercase tracking-wide text-white">
                    API Gateway Configuration
                  </h3>
                  <p className="text-[10px] text-slate-400 font-mono">
                    Connect dashboard to local server or remote cloud tunnel
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsGatewayModalOpen(false)}
                className="p-1 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition-colors cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-5 space-y-4 font-mono text-xs">
              <div>
                <label className="block text-slate-700 font-bold uppercase text-[11px] mb-1.5">
                  FastAPI Backend Base URL (prefix with /api/v1)
                </label>
                <input
                  type="text"
                  value={customGatewayUrl}
                  onChange={(e) => setCustomGatewayUrl(e.target.value)}
                  placeholder="http://localhost:8000/api/v1 or https://xyz.ngrok-free.app/api/v1"
                  className="w-full bg-white border border-[#CBD5E1] rounded-xl px-3 py-2 text-slate-900 focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                />
                <p className="text-[10px] text-slate-500 mt-1">
                  Default: <code className="bg-slate-100 px-1 py-0.5 rounded">http://localhost:8000/api/v1</code>
                </p>
              </div>

              {/* Ping Result Feedback */}
              {testResult && (
                <div
                  className={`p-3 rounded-xl border flex items-start gap-2 ${
                    testResult.ok
                      ? 'bg-emerald-50 text-emerald-900 border-emerald-300'
                      : 'bg-red-50 text-red-900 border-red-300'
                  }`}
                >
                  {testResult.ok ? (
                    <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  ) : (
                    <AlertTriangle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
                  )}
                  <div className="text-[11px] leading-relaxed break-all">
                    {testResult.message}
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between pt-2 border-t border-slate-200 gap-2 flex-wrap">
                <button
                  type="button"
                  onClick={handleTestGateway}
                  disabled={isTestingGateway}
                  className="flex items-center gap-1.5 px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-800 rounded-xl font-bold border border-[#CBD5E1] transition-colors cursor-pointer"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${isTestingGateway ? 'animate-spin' : ''}`} />
                  <span>{isTestingGateway ? 'Testing...' : 'Test Connection'}</span>
                </button>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={handleResetGatewayToDefault}
                    className="px-3 py-2 text-slate-600 hover:text-black transition-colors cursor-pointer"
                  >
                    Reset Default
                  </button>
                  <button
                    type="button"
                    onClick={handleSaveGateway}
                    className="px-4 py-2 bg-black hover:bg-slate-800 text-white rounded-xl font-bold transition-colors cursor-pointer"
                  >
                    Save &amp; Connect
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
};
