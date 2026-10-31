import React from 'react';
import clsx from 'clsx';
import { Keyboard, LogOut, User, X } from 'lucide-react';
import { useConsoleStore } from '../../store/useConsoleStore';
import { ProjectIcon, ProjectIconName } from '../ui/ProjectIcon';

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

  const navItems: Array<{
    id: 'overview' | 'review' | 'ledger' | 'health';
    label: string;
    description: string;
    iconName: ProjectIconName;
    badge: number | null;
    badgeVariant?: 'warning';
  }> = [
    {
      id: 'overview',
      label: 'Overview',
      description: 'Operations cockpit & KPIs',
      iconName: 'app',
      badge: null,
    },
    {
      id: 'review',
      label: 'Receipt Review',
      description: 'Human-in-the-loop triage',
      iconName: 'review',
      badge: pendingReviewCount > 0 ? pendingReviewCount : null,
      badgeVariant: 'warning',
    },
    {
      id: 'ledger',
      label: 'Audit Ledger',
      description: 'Ingestion records & inspector',
      iconName: 'ledger',
      badge: null,
    },
    {
      id: 'health',
      label: 'System & Admin',
      description: 'Engine status, logs & controls',
      iconName: 'settings',
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
          <div className="w-9 h-9 rounded-xl bg-black text-white shadow-xs flex items-center justify-center p-1.5 shrink-0 transition-transform duration-200 hover:scale-105">
            <ProjectIcon name="app" className="w-6 h-6 text-white" />
          </div>
          <div className="min-w-0">
            <div className="text-sm font-bold text-slate-900 tracking-tight leading-tight flex items-center gap-1.5 font-mono">
              <span>ReceiptLedger</span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-600 inline-block animate-pulse" />
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

      {/* ── Main Navigation List with Project SVGs ───────────────────────── */}
      <nav className="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto" aria-label="Main Navigation">
        <div className="px-3 pb-1 text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-400">
          Workspaces
        </div>
        {navItems.map((item) => {
          const isActive = activeNav === item.id;

          return (
            <button
              key={item.id}
              onClick={() => handleNavClick(item.id)}
              className={clsx(
                'w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-left transition-all duration-150 font-medium text-xs cursor-pointer',
                isActive
                  ? 'bg-black text-white font-semibold shadow-xs -translate-y-0.5'
                  : 'text-slate-700 hover:bg-slate-100 hover:text-slate-900 hover:translate-x-0.5'
              )}
            >
              <div className="flex items-center gap-2.5 min-w-0">
                <ProjectIcon
                  name={item.iconName}
                  className={clsx('w-4 h-4 shrink-0', isActive ? 'text-white' : 'text-slate-600')}
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
          className="w-full flex items-center justify-between px-3 py-2 text-xs font-mono text-slate-600 bg-white border border-[#CBD5E1] rounded-xl hover:bg-slate-50 hover:border-slate-400 transition-all duration-150 hover:-translate-y-0.5 cursor-pointer"
          title="Toggle Keyboard Shortcuts"
        >
          <div className="flex items-center gap-2">
            <Keyboard className="w-3.5 h-3.5 text-slate-500" />
            <span>Shortcuts</span>
          </div>
          <kbd className="text-[10px] bg-slate-100 border border-slate-300 px-1 rounded">?</kbd>
        </button>

        {/* User Card */}
        <div className="bg-white border border-[#CBD5E1] rounded-xl p-3 space-y-2">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-8 h-8 rounded-full bg-slate-100 border border-[#CBD5E1] flex items-center justify-center text-slate-700 shrink-0">
              <User className="w-4 h-4" />
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-xs font-semibold text-slate-900 truncate">
                Operations Manager
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
            className="w-full flex items-center justify-center gap-1.5 py-1.5 text-xs font-semibold text-red-600 hover:text-red-700 hover:bg-red-50 border border-transparent hover:border-red-200 rounded-lg transition-colors cursor-pointer"
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
      <aside className="hidden md:flex w-64 bg-white border-r border-[#CBD5E1] flex-col justify-between h-screen shrink-0 select-none">
        {renderContent(false)}
      </aside>

      {isOpenMobile && (
        <div className="md:hidden fixed inset-0 z-50 flex">
          <div
            onClick={onCloseMobile}
            className="fixed inset-0 bg-slate-950/70 transition-opacity"
            aria-hidden="true"
          />

          <aside className="relative w-72 max-w-[85vw] bg-white border-r border-[#CBD5E1] flex flex-col justify-between h-full z-10 shadow-2xl animate-in slide-in-from-left duration-200 select-none">
            {renderContent(true)}
          </aside>
        </div>
      )}
    </>
  );
};
