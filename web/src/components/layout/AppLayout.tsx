import React, { useState } from 'react';
import { Sidebar } from './Sidebar';
import { Menu, Receipt, Upload } from 'lucide-react';
import { useConsoleStore } from '../../store/useConsoleStore';

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
            <div className="w-7 h-7 bg-white text-black rounded-lg flex items-center justify-center font-mono font-bold text-xs shrink-0">
              <Receipt className="w-4 h-4 text-black" />
            </div>
            <div>
              <div className="font-mono font-bold text-xs tracking-wider uppercase text-white flex items-center gap-1.5">
                <span>ReceiptLedger</span>
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block" />
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
            <Upload className="w-4 h-4" />
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

      {/* ── Main Viewport Container (Top bar + Workspaces) ────────────── */}
      <div className="flex-1 flex flex-col min-w-0 h-full overflow-y-auto">
        {children}
      </div>
    </div>
  );
};
