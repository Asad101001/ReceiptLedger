import React, { useState } from 'react';
import { Lock, Mail, ArrowRight, AlertCircle, ShieldCheck } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { ProjectIcon } from '../../components/ui/ProjectIcon';

export const LoginView: React.FC = () => {
  const { login, isLoggingIn } = useAuth();
  const [email, setEmail] = useState('user@receiptledger.com');
  const [password, setPassword] = useState('demo1234');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    try {
      await login({ email: email.trim(), password });
    } catch (err: unknown) {
      if (err instanceof Error) {
        setErrorMsg(err.message || 'Authentication failed. Please verify credentials.');
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
      {/* Container card: Crisp white surface, 1px solid border #CBD5E1, rounded-2xl */}
      <div className="w-full max-w-md bg-white border border-[#CBD5E1] rounded-2xl shadow-sm overflow-hidden transition-all duration-200">
        {/* Brand Header */}
        <div className="p-8 pb-6 border-b border-[#CBD5E1] bg-white text-center">
          <div className="w-14 h-14 bg-black text-white rounded-2xl flex items-center justify-center p-3 mx-auto mb-4 shadow-md">
            <ProjectIcon name="app" className="w-8 h-8 text-white" />
          </div>
          <h1 className="font-mono font-bold text-lg tracking-tight uppercase text-slate-900 leading-tight">
            ReceiptLedger
          </h1>
          <p className="font-mono text-xs text-slate-500 mt-1">
            Operations Console &amp; Audit Ledger
          </p>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-8 space-y-4">
          {/* Error Banner */}
          {errorMsg && (
            <div className="bg-red-50 border border-red-300 text-red-900 text-xs font-mono p-3 rounded-xl flex items-start gap-2.5">
              <AlertCircle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
              <div className="flex-1 space-y-1">
                <div className="font-semibold">Authentication Notice</div>
                <div className="text-[11px] leading-relaxed">{errorMsg}</div>
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-mono font-semibold uppercase text-slate-700 mb-1.5">
              Operator Email
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="operator@receiptledger.com"
                className="w-full pl-10 pr-3 py-2.5 text-xs font-mono bg-white border border-[#CBD5E1] rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-mono font-semibold uppercase text-slate-700 mb-1.5">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-10 pr-3 py-2.5 text-xs font-mono bg-white border border-[#CBD5E1] rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
              />
            </div>
          </div>

          {/* Primary Action Button: Solid black rounded-xl with subtle hover lift */}
          <button
            type="submit"
            disabled={isLoggingIn}
            className="w-full flex items-center justify-center gap-2 bg-black hover:bg-slate-800 disabled:opacity-50 text-white font-mono text-xs font-bold uppercase py-3 px-4 rounded-xl border border-black transition-all duration-150 hover:-translate-y-0.5 hover:shadow-sm cursor-pointer mt-2"
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

        {/* Demo Credentials Quick-Fill Card */}
        <div className="bg-[#F8FAFC] border-t border-[#CBD5E1] p-4 text-xs font-mono text-slate-600">
          <div className="flex items-center justify-between">
            <span className="font-semibold text-slate-700 uppercase text-[11px] flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              Demo Access
            </span>
            <button
              type="button"
              onClick={handleFillDemo}
              className="text-[11px] text-emerald-700 hover:text-emerald-900 font-bold underline cursor-pointer"
            >
              Autofill Demo Credentials
            </button>
          </div>
          <div className="mt-2 bg-white border border-[#CBD5E1] p-2.5 rounded-xl text-[11px] space-y-1">
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
      </div>

      {/* Footer System Info */}
      <div className="mt-5 text-center text-[11px] font-mono text-slate-400 space-y-0.5">
        <div>ReceiptLedger Monorepo • Production Console</div>
        <div>SPM-458 • Department of Computer Science • University of Karachi</div>
      </div>
    </div>
  );
};
