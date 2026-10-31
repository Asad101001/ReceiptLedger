import React from 'react';
import clsx from 'clsx';
import {
  LayoutDashboard,
  CheckSquare,
  ScrollText,
  Activity,
  Keyboard,
  LogOut,
  Receipt,
  User,
  X,
} from 'lucide-react';
import { useConsoleStore } from '../../store/useConsoleStore';

interface SidebarProps {
  userEmail?: string;
  onLogout: () => void;
  pendingReviewCount?: number;
  isOpenMobile?: boolean;
  onCloseMobile?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  userEmail = 'user@receiptledger.com',
  onLogout,
  pendingReviewCount = 7,
  isOpenMobile = false,
  onCloseMobile,
}) => {
  const { activeNav, setActiveNav, toggleShortcutsPanel } = useConsoleStore();

  const navItems = [
    {
      id: 'overview' as const,
      label: 'Overview',
      description: 'Operations cockpit & KPIs',
      icon: LayoutDashboard,
      badge: null,
    },
    {
      id: 'review' as const,
      label: 'Receipt Review',
      description: 'Human-in-the-loop triage',
      icon: CheckSquare,
      badge: pendingReviewCount > 0 ? pendingReviewCount : null,
      badgeVariant: 'warning',
    },
    {
      id: 'ledger' as const,
      label: 'Audit Ledger',
      description: 'Ingestion records & inspector',
      icon: ScrollText,
      badge: null,
    },
    {
      id: 'health' as const,
      label: 'System Health',
      description: 'Engines & observability runs',
      icon: Activity,
      badge: null,
    },
  ];

  const handleNavClick = (id: typeof activeNav) => {
    setActiveNav(id);
    if (onCloseMobile) onCloseMobile();
  };

  const handleShortcutsClick = () => {
    toggleShortcutsPanel();
    if (onCloseMobile) onCloseMobile();
  };

  const renderContent = (isMobileView = false) => (
    <>
      {/* ── Top Brand Header ────────────────────────────────────────────── */}
      <div className="p-4 border-b border-[#CBD5E1] flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 bg-black text-white rounded-lg flex items-center justify-center font-mono font-bold shrink-0">
            <Receipt className="w-5 h-5 text-white" />
          </div>
          <div className="min-w-0">
            <div className="text-sm font-bold text-slate-900 tracking-tight leading-tight flex items-center gap-1.5">
              <span>ReceiptLedger</span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-600 inline-block" />
            </div>
            <div className="text-[10px] font-mono text-slate-500 uppercase tracking-wider">
              Operations Console
            </div>
          </div>
        </div>

        {isMobileView && onCloseMobile && (
          <button
            type="button"
            onClick={onCloseMobile}
            aria-label="Close navigation"
            className="p-1 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* ── Main Navigation List ────────────────────────────────────────── */}
      <nav className="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto" aria-label="Main Navigation">
        <div className="px-3 pb-1 text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-400">
          Workspaces
        </div>
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeNav === item.id;

          return (
            <button
              key={item.id}
              onClick={() => handleNavClick(item.id)}
              className={clsx(
                'w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-left transition-colors font-medium text-xs',
                isActive
                  ? 'bg-black text-white font-semibold'
                  : 'text-slate-700 hover:bg-slate-100 hover:text-slate-900'
              )}
            >
              <div className="flex items-center gap-2.5 min-w-0">
                <Icon
                  className={clsx(
                    'w-4 h-4 shrink-0',
                    isActive ? 'text-white' : 'text-slate-500'
                  )}
                />
                <div className="truncate">
                  <div>{item.label}</div>
                </div>
              </div>

              {item.badge !== null && (
                <span
                  className={clsx(
                    'text-[10px] font-mono font-bold px-2 py-0.5 rounded-full shrink-0',
                    isActive
                      ? 'bg-amber-400 text-black'
                      : 'bg-amber-100 text-amber-900 border border-amber-300'
                  )}
                >
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* ── Bottom Section: Profile, Shortcuts & Logout ─────────────────── */}
      <div className="p-3 border-t border-[#CBD5E1] space-y-3 bg-[#F8FAFC]">
        {/* Keyboard Shortcuts Trigger */}
        <button
          onClick={handleShortcutsClick}
          className="w-full flex items-center justify-between px-3 py-2 text-xs font-mono text-slate-600 bg-white border border-[#CBD5E1] rounded-lg hover:bg-slate-50 transition-colors"
          title="Toggle Keyboard Shortcuts"
        >
          <div className="flex items-center gap-2">
            <Keyboard className="w-3.5 h-3.5 text-slate-500" />
            <span>Shortcuts</span>
          </div>
          <kbd className="text-[10px]">?</kbd>
        </button>

        {/* User Card */}
        <div className="bg-white border border-[#CBD5E1] rounded-xl p-3 space-y-2">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-8 h-8 rounded-full bg-slate-200 border border-[#CBD5E1] flex items-center justify-center text-slate-700 shrink-0">
              <User className="w-4 h-4" />
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-xs font-semibold text-slate-900 truncate">
                Demo Manager
              </div>
              <div className="text-[10px] font-mono text-slate-500 truncate" title={userEmail}>
                {userEmail}
              </div>
            </div>
            <span className="text-[10px] font-mono font-bold bg-slate-100 border border-[#CBD5E1] px-1.5 py-0.5 rounded text-slate-700 shrink-0">
              PKR
            </span>
          </div>

          <button
            onClick={onLogout}
            className="w-full flex items-center justify-center gap-1.5 py-1.5 text-xs font-semibold text-red-600 hover:text-red-700 hover:bg-red-50 border border-transparent hover:border-red-200 rounded-lg transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Sign Out</span>
          </button>
        </div>
      </div>
    </>
  );

  return (
    <>
      {/* ── Persistent Desktop Sidebar (hidden on mobile, visible on md+) ── */}
      <aside className="hidden md:flex w-64 bg-white border-r border-[#CBD5E1] flex-col justify-between h-screen shrink-0 select-none">
        {renderContent(false)}
      </aside>

      {/* ── Mobile Drawer Overlay (visible strictly when toggled on < md) ── */}
      {isOpenMobile && (
        <div className="md:hidden fixed inset-0 z-50 flex">
          {/* Backdrop */}
          <div
            onClick={onCloseMobile}
            className="fixed inset-0 bg-slate-950/70 transition-opacity"
            aria-hidden="true"
          />

          {/* Drawer container */}
          <aside className="relative w-72 max-w-[85vw] bg-white border-r border-[#CBD5E1] flex flex-col justify-between h-full z-10 shadow-2xl animate-in slide-in-from-left duration-200 select-none">
            {renderContent(true)}
          </aside>
        </div>
      )}
    </>
  );
};
