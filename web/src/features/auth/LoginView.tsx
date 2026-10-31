import React, { useState } from 'react';
import { Lock, Mail, ArrowRight, ShieldCheck, AlertCircle, WifiOff } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { getApiBaseUrl } from '../../api/client';

export const LoginView: React.FC = () => {
  const { login, isLoggingIn, enterDevMockMode } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isNetworkFailure, setIsNetworkFailure] = useState(false);

  const isDev = import.meta.env.DEV;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setIsNetworkFailure(false);

    try {
      await login({ email: email.trim(), password });
    } catch (err: unknown) {
      if (err instanceof Error) {
        const message = err.message || 'Authentication failed. Check credentials.';
        setErrorMsg(message);
        if (message.toLowerCase().includes('gateway') || message.toLowerCase().includes('connect') || message.toLowerCase().includes('network')) {
          setIsNetworkFailure(true);
        }
      } else {
        setErrorMsg('Authentication failed.');
      }
    }
  };

  const handleFillDemo = () => {
    setEmail('user@receiptledger.com');
    setPassword('demo1234');
    setErrorMsg(null);
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col items-center justify-center p-4 antialiased select-none">
      {/* Container card: Crisp white surface, 1px border #CBD5E1, rounded-2xl (Pinterest reference) */}
      <div className="w-full max-w-md bg-white border border-[#CBD5E1] rounded-2xl overflow-hidden">
        {/* Brand Header */}
        <div className="p-6 pb-4 border-b border-[#CBD5E1] bg-white">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white border border-[#CBD5E1] rounded-xl flex items-center justify-center p-1.5 shrink-0 shadow-xs">
              <img src="/icons/app_icon.svg" alt="ReceiptLedger" className="w-7 h-7 object-contain" />
            </div>
            <div>
              <h1 className="font-mono font-bold text-sm tracking-wider uppercase text-slate-900 leading-tight">
                RECEIPTLEDGER OPERATIONS CONSOLE
              </h1>
              <p className="font-mono text-xs text-slate-500 mt-0.5">
                Desktop Authentication Gateway
              </p>
            </div>
          </div>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {/* Error Banner with solid colors */}
          {errorMsg && (
            <div className="bg-red-50 border border-red-300 text-red-900 text-xs font-mono p-3 rounded-xl flex items-start gap-2.5">
              <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
              <div className="flex-1 space-y-1">
                <div className="font-semibold">Authentication Error</div>
                <div className="text-[11px] leading-relaxed">{errorMsg}</div>

                {/* Explicit Offline Dev Mode Option when API is unavailable */}
                {(isNetworkFailure || isDev) && (
                  <div className="pt-2">
                    <button
                      type="button"
                      onClick={enterDevMockMode}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-white bg-slate-900 hover:bg-black rounded-lg transition-colors cursor-pointer"
                    >
                      <WifiOff className="w-3.5 h-3.5" />
                      <span>Enter Offline Dev Mode (Mock Data)</span>
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-mono font-semibold uppercase text-slate-700 mb-1.5">
              Operator Email Address
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="operator@receiptledger.com"
                className="w-full pl-9 pr-3 py-2 text-xs font-mono bg-white border border-[#CBD5E1] rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-mono font-semibold uppercase text-slate-700 mb-1.5">
              Master Session Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-9 pr-3 py-2 text-xs font-mono bg-white border border-[#CBD5E1] rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
              />
            </div>
          </div>

          {/* Primary Action Button: Solid black pill/rounded-xl */}
          <button
            type="submit"
            disabled={isLoggingIn}
            className="w-full flex items-center justify-center gap-2 bg-black hover:bg-slate-800 disabled:opacity-50 text-white font-mono text-xs font-bold uppercase py-3 px-4 rounded-xl border border-black transition-colors cursor-pointer"
          >
            {isLoggingIn ? (
              <span className="flex items-center gap-2">
                <span className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin inline-block" />
                <span>Authenticating Session...</span>
              </span>
            ) : (
              <>
                <span>Sign In to Console</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Demo Credentials Hint (Visible strictly in development mode) */}
        {true && (
          <div className="bg-[#F8FAFC] border-t border-[#CBD5E1] p-4 text-xs font-mono text-slate-600 space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-semibold text-slate-700 uppercase text-[11px] flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                Demo Credentials (Dev Mode)
              </span>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleFillDemo}
                  className="text-[11px] text-blue-700 hover:text-blue-900 font-semibold underline cursor-pointer"
                >
                  Autofill
                </button>
                <span className="text-slate-300">•</span>
                <button
                  type="button"
                  onClick={enterDevMockMode}
                  className="text-[11px] text-amber-800 hover:text-amber-950 font-bold underline cursor-pointer flex items-center gap-1"
                >
                  <WifiOff className="w-3 h-3 text-amber-600" />
                  <span>Offline Dev Mode</span>
                </button>
              </div>
            </div>
            <div className="bg-white border border-[#CBD5E1] p-2.5 rounded-xl text-[11px] space-y-1">
              <div className="flex justify-between">
                <span className="text-slate-500">Email:</span>
                <strong className="text-slate-900">user@receiptledger.com</strong>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Password:</span>
                <strong className="text-slate-900">demo1234</strong>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Footer System Info */}
      <div className="mt-3 text-center text-[10px] font-mono text-slate-500">Gateway: <span className="font-semibold text-slate-700">{getApiBaseUrl()}</span></div>
      <div className="mt-2 text-center text-[11px] font-mono text-slate-400">
        ReceiptLedger Monorepo Gateway • Scope: Admin, Audit &amp; Triage
      </div>
    </div>
  );
};
