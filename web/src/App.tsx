import React from 'react';
import { useAuth } from './hooks/useAuth';
import { LoginView } from './features/auth/LoginView';
import { OperationsConsole } from './features/console/OperationsConsole';

export const AppContent: React.FC = () => {
  const { isAuthenticated, isLoading, user, logout, isMockMode, enterDevMockMode } = useAuth();

  // Initial session verification loader (solid flat styling matching Pinterest references)
  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#F8FAFC] flex flex-col items-center justify-center p-4 select-none">
        <div className="bg-white border border-[#CBD5E1] p-8 rounded-2xl text-center space-y-3 font-mono max-w-sm w-full">
          <div className="w-10 h-10 bg-black text-white rounded-xl flex items-center justify-center font-bold mx-auto">
            RL
          </div>
          <div className="text-xs font-bold uppercase text-slate-900">
            ReceiptLedger Operations Console
          </div>
          <div className="text-[11px] text-slate-500">
            Verifying security session...
          </div>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginView />;
  }

  return (
    <OperationsConsole
      userEmail={user?.email}
      onLogout={logout}
      isMockMode={isMockMode}
      onEnterDevMockMode={enterDevMockMode}
    />
  );
};

export const App: React.FC = () => {
  return <AppContent />;
};

export default App;
