import React, { useState } from 'react';
import { Lock, Mail, ArrowRight, AlertCircle, ShieldCheck, UserPlus, User } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { ProjectIcon } from '../../components/ui/ProjectIcon';

export const LoginView: React.FC = () => {
  const { login, isLoggingIn, register, isRegistering } = useAuth();
  const [mode, setMode] = useState<'signin' | 'register'>('signin');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const isSubmitting = isLoggingIn || isRegistering;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    const cleanEmail = email.trim();
    if (!cleanEmail) {
      setErrorMsg('Please enter an email address.');
      return;
    }

    if (mode === 'register') {
      if (password.length < 6) {
        setErrorMsg('Password must be at least 6 characters.');
        return;
      }
      if (password !== confirmPassword) {
        setErrorMsg('Passwords do not match.');
        return;
      }

      try {
        await register({
          email: cleanEmail,
          password,
          full_name: fullName.trim() || 'Asad',
        });
      } catch (err: unknown) {
        if (err instanceof Error) {
          setErrorMsg(err.message || 'Registration failed.');
        } else {
          setErrorMsg('Registration failed.');
        }
      }
    } else {
      try {
        await login({ email: cleanEmail, password });
      } catch (err: unknown) {
        if (err instanceof Error) {
          setErrorMsg(err.message || 'Authentication failed. Please verify credentials.');
        } else {
          setErrorMsg('Authentication failed.');
        }
      }
    }
  };

  const handleFillAsad = () => {
    setFullName('Asad');
    setEmail('muhammadasadk42@gmail.com');
    setPassword('asad1234');
    setConfirmPassword('asad1234');
    setErrorMsg(null);
  };

  const handleFillDemo = () => {
    setFullName('Demo Household Manager');
    setEmail('user@receiptledger.com');
    setPassword('demo1234');
    setConfirmPassword('demo1234');
    setErrorMsg(null);
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex flex-col items-center justify-center p-4 antialiased select-none">
      {/* Container card: Crisp white surface, 1px solid border #CBD5E1, rounded-2xl */}
      <div className="w-full max-w-md bg-white border border-[#CBD5E1] rounded-2xl shadow-sm overflow-hidden transition-all duration-200">
        {/* Brand Header */}
        <div className="p-7 pb-5 border-b border-[#CBD5E1] bg-white text-center">
          <div className="w-13 h-13 bg-black text-white rounded-2xl flex items-center justify-center p-3 mx-auto mb-3 shadow-md">
            <ProjectIcon name="app" className="w-7 h-7 text-white" />
          </div>
          <h1 className="font-mono font-bold text-lg tracking-tight uppercase text-slate-900 leading-tight">
            ReceiptLedger
          </h1>
          <p className="font-mono text-xs text-slate-500 mt-1">
            Operations Console &amp; Audit Ledger
          </p>

          {/* Mode Tabs */}
          <div className="flex bg-[#F1F5F9] p-1 rounded-xl mt-4 border border-[#CBD5E1]">
            <button
              type="button"
              onClick={() => { setMode('signin'); setErrorMsg(null); }}
              className={`flex-1 py-1.5 text-xs font-mono font-semibold rounded-lg transition-all ${
                mode === 'signin'
                  ? 'bg-white text-slate-900 shadow-xs border border-[#CBD5E1]'
                  : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              Sign In
            </button>
            <button
              type="button"
              onClick={() => { setMode('register'); setErrorMsg(null); }}
              className={`flex-1 py-1.5 text-xs font-mono font-semibold rounded-lg transition-all ${
                mode === 'register'
                  ? 'bg-white text-slate-900 shadow-xs border border-[#CBD5E1]'
                  : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              Create Account
            </button>
          </div>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-7 space-y-4">
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

          {mode === 'register' && (
            <div>
              <label className="block text-xs font-mono font-semibold uppercase text-slate-700 mb-1.5">
                Full Name
              </label>
              <div className="relative">
                <User className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Asad"
                  className="w-full pl-10 pr-3 py-2.5 text-xs font-mono bg-white border border-[#CBD5E1] rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                />
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-mono font-semibold uppercase text-slate-700 mb-1.5">
              Email Address
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
              Password {mode === 'register' && '(min 6 characters)'}
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

          {mode === 'register' && (
            <div>
              <label className="block text-xs font-mono font-semibold uppercase text-slate-700 mb-1.5">
                Confirm Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-3 py-2.5 text-xs font-mono bg-white border border-[#CBD5E1] rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                />
              </div>
            </div>
          )}

          {/* Primary Action Button */}
          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full flex items-center justify-center gap-2 bg-black hover:bg-slate-800 disabled:opacity-50 text-white font-mono text-xs font-bold uppercase py-3 px-4 rounded-xl border border-black transition-all duration-150 hover:-translate-y-0.5 hover:shadow-sm cursor-pointer mt-2"
          >
            {isSubmitting ? (
              <span className="flex items-center gap-2">
                <span className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin inline-block" />
                <span>{mode === 'register' ? 'Creating Account...' : 'Authenticating Session...'}</span>
              </span>
            ) : mode === 'register' ? (
              <>
                <span>Register &amp; Open Console</span>
                <UserPlus className="w-4 h-4" />
              </>
            ) : (
              <>
                <span>Sign In to Console</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Quick Credentials Card */}
        <div className="bg-[#F8FAFC] border-t border-[#CBD5E1] p-4 text-xs font-mono text-slate-600">
          <div className="flex items-center justify-between mb-2">
            <span className="font-semibold text-slate-700 uppercase text-[11px] flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              Quick Fill Credentials
            </span>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={handleFillAsad}
              className="p-2 text-left bg-white hover:bg-slate-50 border border-[#CBD5E1] rounded-xl text-[11px] transition-colors cursor-pointer"
            >
              <div className="font-bold text-slate-900">Asad</div>
              <div className="text-[10px] text-slate-500 truncate">muhammadasadk42@...</div>
              <div className="text-[10px] text-emerald-700 font-semibold mt-0.5">asad1234</div>
            </button>
            <button
              type="button"
              onClick={handleFillDemo}
              className="p-2 text-left bg-white hover:bg-slate-50 border border-[#CBD5E1] rounded-xl text-[11px] transition-colors cursor-pointer"
            >
              <div className="font-bold text-slate-900">Autofill Demo Account</div>
              <div className="text-[10px] text-slate-500 truncate">user@receiptledger...</div>
              <div className="text-[10px] text-emerald-700 font-semibold mt-0.5">demo1234</div>
            </button>
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
