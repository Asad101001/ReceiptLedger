import React, { useState } from 'react';
import { Sidebar } from './Sidebar';
import { Menu, ExternalLink, Code2 } from 'lucide-react';
import { ProjectIcon } from '../ui/ProjectIcon';
import { useConsoleStore } from '../../store/useConsoleStore';
import { getApiBaseUrl } from '../../api/client';

interface AppLayoutProps {
  children: React.ReactNode;
  userEmail?: string;
  onLogout: () => void;
  pendingReviewCount?: number;
}

export const AppLayout: React.FC<AppLayoutProps> = ({
  children,
  userEmail,
  onLogout,
  pendingReviewCount = 7,
}) => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const { toggleUploadDrawer } = useConsoleStore();

  const handleOpenDocs = () => {
    const base = getApiBaseUrl();
    const docsUrl = base.replace(/\/api\/v1\/?$/, '/docs');
    window.open(docsUrl, '_blank');
  };

  return (
    <div className="flex flex-col md:flex-row h-screen w-screen overflow-hidden bg-[#F8FAFC]">
      {/* ── Mobile Top App Bar (Visible strictly on < md) ──────────────── */}
      <header className="md:hidden bg-[#0F172A] text-white px-4 py-2.5 flex items-center justify-between border-b border-[#334155] shrink-0 z-20 select-none">
        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={() => setIsMobileMenuOpen(true)}
            aria-label="Open navigation menu"
            className="p-1.5 rounded-lg bg-slate-800 border border-slate-700 text-slate-200 hover:text-white hover:bg-slate-700 transition-colors cursor-pointer"
          >
            <Menu className="w-5 h-5" />
          </button>
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 bg-white text-black rounded-lg flex items-center justify-center p-1 shrink-0">
              <ProjectIcon name="app" className="w-5 h-5 text-black" />
            </div>
            <div>
              <div className="font-mono font-bold text-xs tracking-wider uppercase text-white flex items-center gap-1.5">
                <span>ReceiptLedger</span>
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block animate-pulse" />
              </div>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {pendingReviewCount > 0 && (
            <span className="bg-amber-400 text-black font-mono font-bold text-[10px] px-2 py-0.5 rounded-full">
              {pendingReviewCount} Review
            </span>
          )}
          <button
            type="button"
            onClick={toggleUploadDrawer}
            title="Upload Receipt Image"
            className="p-1.5 rounded-lg bg-slate-800 border border-slate-700 text-slate-200 hover:text-white transition-colors cursor-pointer"
          >
            <ProjectIcon name="capture" className="w-4 h-4 text-white" />
          </button>
        </div>
      </header>

      {/* ── Sidebar (Desktop Persistent + Mobile Drawer) ──────────────── */}
      <Sidebar
        userEmail={userEmail}
        onLogout={onLogout}
        pendingReviewCount={pendingReviewCount}
        isOpenMobile={isMobileMenuOpen}
        onCloseMobile={() => setIsMobileMenuOpen(false)}
      />

      {/* ── Main Viewport Container (Top bar + Workspaces + Proper Footer) ── */}
      <div className="flex-1 flex flex-col min-w-0 h-full overflow-y-auto">
        <div className="flex-1">
          {children}
        </div>

        {/* ── Decent Operational Footer ─────────────────────────────────── */}
        <footer className="mt-auto bg-white border-t border-[#CBD5E1] px-4 sm:px-6 py-3 text-xs font-mono text-slate-500 flex flex-col sm:flex-row items-center justify-between gap-2.5 select-none shrink-0">
          <div className="flex items-center gap-2 flex-wrap justify-center sm:justify-start">
            <span className="font-bold text-slate-900 flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 inline-block" />
              ReceiptLedger
            </span>
            <span className="text-slate-300">•</span>
            <span>SPM-458 Project</span>
            <span className="text-slate-300">•</span>
            <span className="text-slate-600">v1.0.0 Production Console</span>
          </div>

          <div className="flex items-center gap-3 text-[11px] flex-wrap justify-center">
            <a
              href="https://github.com/Asad101001/ReceiptLedger"
              target="_blank"
              rel="noopener noreferrer"
              className="text-slate-600 hover:text-black transition-colors underline decoration-slate-300 hover:decoration-black inline-flex items-center gap-1"
            >
              <span>GitHub Repo</span>
              <ExternalLink className="w-3 h-3 text-slate-400" />
            </a>

            <span className="text-slate-300">•</span>

            <button
              type="button"
              onClick={handleOpenDocs}
              className="text-slate-600 hover:text-black transition-colors underline decoration-slate-300 hover:decoration-black cursor-pointer inline-flex items-center gap-1"
            >
              <Code2 className="w-3 h-3 text-slate-400" />
              <span>FastAPI Docs</span>
            </button>

            <span className="text-slate-300">•</span>

            <span className="text-slate-400">University of Karachi</span>
          </div>
        </footer>
      </div>
    </div>
  );
};
