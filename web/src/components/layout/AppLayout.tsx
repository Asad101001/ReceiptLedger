import React from 'react';
import { Sidebar } from './Sidebar';

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
  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#F8FAFC]">
      {/* ── Fixed Desktop Left Sidebar ────────────────────────── */}
      <Sidebar
        userEmail={userEmail}
        onLogout={onLogout}
        pendingReviewCount={pendingReviewCount}
      />

      {/* ── Main Viewport Container (Top bar + Workspaces) ────── */}
      <div className="flex-1 flex flex-col min-w-0 h-full overflow-y-auto">
        {children}
      </div>
    </div>
  );
};
