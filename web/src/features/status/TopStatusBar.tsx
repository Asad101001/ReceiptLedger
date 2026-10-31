import React from 'react';
import { LogOut, WifiOff, AlertTriangle, User } from 'lucide-react';
import { HealthResponse } from '../../types';
import { useConsoleStore } from '../../store/useConsoleStore';
import { ProjectIcon } from '../../components/ui/ProjectIcon';

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
  userEmail,
  onLogout,
  isMockMode = false,
}) => {
  const { toggleUploadDrawer, setActiveNav } = useConsoleStore();

  const engines = health?.engines;
  const isCloudVisionOk = engines?.cloud_vision ? engines.cloud_vision.startsWith('ok') : false;
  const isGeminiOk = engines?.gemini ? engines.gemini.startsWith('ok') : false;
  const isDbOk = Boolean(engines?.database && !engines.database.includes('error') && !engines.database.includes('unavailable'));

  const allOperational = isCloudVisionOk && isGeminiOk && isDbOk;

  return (
    <header className="bg-white border-b border-[#CBD5E1] text-slate-900 px-4 sm:px-6 py-3 select-none">
      <div className="flex items-center justify-between gap-3">
        {/* ── Left: Brand emblem + title + streamlined status pill ── */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-xl bg-black text-white shadow-xs flex items-center justify-center p-1.5 shrink-0 transition-transform duration-200 hover:scale-105">
            <ProjectIcon name="app" className="w-5 h-5 text-white" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-mono font-bold text-xs sm:text-sm tracking-wide uppercase text-slate-900">
                ReceiptLedger
              </h1>
              <span className="font-mono text-[9px] font-semibold bg-slate-100 text-slate-700 border border-[#CBD5E1] px-1.5 py-0.2 rounded">
                Console
              </span>
            </div>
            <div className="text-[10px] sm:text-[11px] font-mono text-slate-500 flex items-center gap-2 mt-0.5">
              {/* Clean unified status pill */}
              {isMockMode ? (
                <button
                  type="button"
                  onClick={() => setActiveNav('health')}
                  className="inline-flex items-center gap-1.5 text-amber-900 bg-amber-50 border border-amber-300 px-2 py-0.5 rounded-full font-semibold text-[10px] hover:bg-amber-100 transition-colors cursor-pointer"
                  title="Click to view System Admin Console"
                >
                  <WifiOff className="w-3 h-3 text-amber-700" />
                  <span>Offline Fixtures</span>
                </button>
              ) : isHealthLoading ? (
                <span className="inline-flex items-center gap-1.5 text-slate-500 text-[10px]">
                  <span className="w-1.5 h-1.5 rounded-full bg-slate-400 animate-pulse" />
                  <span>Synchronizing...</span>
                </span>
              ) : allOperational ? (
                <button
                  type="button"
                  onClick={() => setActiveNav('health')}
                  className="inline-flex items-center gap-1.5 text-emerald-800 bg-emerald-50 border border-emerald-300 px-2 py-0.5 rounded-full font-semibold text-[10px] hover:bg-emerald-100 transition-colors cursor-pointer"
                  title="Click to view System Admin Console"
                >
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block animate-pulse" />
                  <span>Cloud Synced</span>
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => setActiveNav('health')}
                  className="inline-flex items-center gap-1.5 text-amber-900 bg-amber-50 border border-amber-300 px-2 py-0.5 rounded-full font-semibold text-[10px] hover:bg-amber-100 transition-colors cursor-pointer"
                  title="Click to view System Admin Console"
                >
                  <AlertTriangle className="w-3 h-3 text-amber-600" />
                  <span>System Degraded</span>
                </button>
              )}

              <span className="text-slate-300">•</span>
              <span className="hidden sm:inline">Admin, Audit &amp; Human Triage</span>
            </div>
          </div>
        </div>

        {/* ── Right: Clean, minimal action bar ── */}
        <div className="flex items-center gap-2.5">
          {/* Primary Action: Upload Receipt with custom capture icon */}
          <button
            type="button"
            onClick={toggleUploadDrawer}
            title="Upload and ingest receipt image"
            className="flex items-center gap-1.5 bg-black hover:bg-slate-800 text-white font-mono text-xs font-semibold px-3.5 py-2 rounded-xl border border-black transition-all duration-150 hover:-translate-y-0.5 hover:shadow-xs cursor-pointer"
          >
            <ProjectIcon name="capture" className="w-4 h-4 text-white" />
            <span>Upload Receipt</span>
          </button>

          {/* User Profile Card */}
          <div className="flex items-center gap-2 text-xs font-mono bg-[#F8FAFC] border border-[#CBD5E1] px-3 py-1.5 rounded-xl">
            <div className="w-5 h-5 rounded-full bg-slate-200 border border-slate-300 flex items-center justify-center text-slate-700 shrink-0">
              <User className="w-3 h-3" />
            </div>
            <span className="hidden md:inline text-slate-700 truncate max-w-[130px] font-medium" title={userEmail}>
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
