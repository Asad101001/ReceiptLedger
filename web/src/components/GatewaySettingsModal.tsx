import React, { useState } from 'react';
import { X, Server, CheckCircle2, AlertTriangle, RefreshCw, Zap, Laptop, Globe, ArrowRight } from 'lucide-react';
import { getApiBaseUrl, setApiBaseUrl, testGatewayHealth, DEFAULT_STATIC_GATEWAY } from '../api/client';

interface GatewaySettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  onGatewayChanged?: (newUrl: string) => void;
}

export const GatewaySettingsModal: React.FC<GatewaySettingsModalProps> = ({
  isOpen,
  onClose,
  onGatewayChanged,
}) => {
  const currentUrl = getApiBaseUrl();
  const [urlInput, setUrlInput] = useState(currentUrl);
  const [testResult, setTestResult] = useState<{
    tested: boolean;
    ok: boolean;
    status?: string;
    message?: string;
    latencyMs?: number;
  } | null>(null);
  const [isTesting, setIsTesting] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  if (!isOpen) return null;

  const handleTest = async (testUrl?: string) => {
    const target = testUrl || urlInput;
    setIsTesting(true);
    setTestResult(null);
    setSaveSuccess(false);
    try {
      const res = await testGatewayHealth(target);
      setTestResult({
        tested: true,
        ok: res.ok,
        status: res.status,
        message: res.message,
        latencyMs: res.latencyMs,
      });
    } catch (err) {
      setTestResult({
        tested: true,
        ok: false,
        message: err instanceof Error ? err.message : String(err),
      });
    } finally {
      setIsTesting(false);
    }
  };

  const handleApply = (urlToSave?: string) => {
    const finalUrl = (urlToSave || urlInput).trim().replace(/\/+$/, '');
    setApiBaseUrl(finalUrl);
    setSaveSuccess(true);
    if (onGatewayChanged) {
      onGatewayChanged(finalUrl);
    }
    setTimeout(() => {
      onClose();
      // Reload window or query invalidation is handled by parent, but reloading ensures all active queries use the new origin
      if (typeof window !== 'undefined') {
        window.location.reload();
      }
    }, 600);
  };

  const selectPreset = (presetUrl: string) => {
    setUrlInput(presetUrl);
    handleTest(presetUrl);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs select-none antialiased animate-in fade-in duration-150">
      <div className="bg-white border border-[#CBD5E1] rounded-2xl shadow-xl w-full max-w-lg overflow-hidden transition-all">
        {/* Header */}
        <div className="px-6 py-4 border-b border-[#CBD5E1] flex items-center justify-between bg-[#F8FAFC]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-black text-white flex items-center justify-center shrink-0">
              <Server className="w-4 h-4 text-white" />
            </div>
            <div>
              <h3 className="font-mono font-bold text-sm text-slate-900 uppercase tracking-tight">
                API Gateway Configuration
              </h3>
              <p className="font-mono text-[11px] text-slate-500">
                Connect Web Console to Live Backend or Permanent Static Tunnel
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="text-slate-400 hover:text-slate-700 transition-colors p-1.5 rounded-lg hover:bg-slate-200 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-4">
          {/* Preset Buttons */}
          <div>
            <label className="block text-[11px] font-mono font-bold uppercase text-slate-700 mb-2">
              Quick Presets
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => selectPreset(DEFAULT_STATIC_GATEWAY)}
                className={`flex items-start gap-2.5 p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                  urlInput === DEFAULT_STATIC_GATEWAY
                    ? 'border-emerald-600 bg-emerald-50/60 ring-1 ring-emerald-500'
                    : 'border-[#CBD5E1] bg-white hover:border-slate-400 hover:bg-slate-50'
                }`}
              >
                <Zap className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div>
                  <div className="font-mono font-bold text-xs text-slate-900 flex items-center gap-1.5">
                    <span>Static Ngrok Tunnel</span>
                    <span className="text-[9px] bg-emerald-100 text-emerald-800 font-bold px-1.5 py-0.2 rounded">
                      HTTPS Live
                    </span>
                  </div>
                  <div className="font-mono text-[10px] text-slate-500 truncate max-w-[190px]">
                    disagree-slick-record.ngrok-free.dev
                  </div>
                </div>
              </button>

              <button
                type="button"
                onClick={() => selectPreset('http://localhost:8000/api/v1')}
                className={`flex items-start gap-2.5 p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                  urlInput === 'http://localhost:8000/api/v1'
                    ? 'border-slate-800 bg-slate-100 ring-1 ring-black'
                    : 'border-[#CBD5E1] bg-white hover:border-slate-400 hover:bg-slate-50'
                }`}
              >
                <Laptop className="w-4 h-4 text-slate-700 shrink-0 mt-0.5" />
                <div>
                  <div className="font-mono font-bold text-xs text-slate-900 flex items-center gap-1.5">
                    <span>Local Loopback</span>
                    <span className="text-[9px] bg-slate-200 text-slate-800 font-bold px-1.5 py-0.2 rounded">
                      HTTP Dev
                    </span>
                  </div>
                  <div className="font-mono text-[10px] text-slate-500 truncate max-w-[190px]">
                    http://localhost:8000/api/v1
                  </div>
                </div>
              </button>
            </div>
          </div>

          {/* Custom URL Input */}
          <div>
            <label className="block text-[11px] font-mono font-bold uppercase text-slate-700 mb-1.5">
              Target API Base URL
            </label>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <Globe className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
                <input
                  type="text"
                  value={urlInput}
                  onChange={(e) => {
                    setUrlInput(e.target.value);
                    setTestResult(null);
                    setSaveSuccess(false);
                  }}
                  placeholder="https://.../api/v1"
                  className="w-full pl-9 pr-3 py-2 text-xs font-mono bg-white border border-[#CBD5E1] rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-black focus:ring-1 focus:ring-black"
                />
              </div>
              <button
                type="button"
                onClick={() => handleTest()}
                disabled={isTesting || !urlInput.trim()}
                className="px-3.5 py-2 text-xs font-mono font-semibold bg-slate-100 hover:bg-slate-200 border border-[#CBD5E1] text-slate-800 rounded-xl transition-colors flex items-center gap-1.5 disabled:opacity-50 cursor-pointer"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${isTesting ? 'animate-spin' : ''}`} />
                <span>Test Ping</span>
              </button>
            </div>
          </div>

          {/* Live Ping Status Notice */}
          {testResult && (
            <div
              className={`p-3 rounded-xl border text-xs font-mono flex items-start gap-2.5 ${
                testResult.ok
                  ? 'bg-emerald-50 border-emerald-300 text-emerald-900'
                  : 'bg-red-50 border-red-300 text-red-900'
              }`}
            >
              {testResult.ok ? (
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
              ) : (
                <AlertTriangle className="w-4 h-4 text-red-600 shrink-0 mt-0.5" />
              )}
              <div className="flex-1 space-y-0.5">
                <div className="font-bold flex items-center justify-between">
                  <span>{testResult.ok ? 'Connection Verified' : 'Gateway Unreachable'}</span>
                  {testResult.latencyMs !== undefined && (
                    <span className="text-[10px] font-semibold text-slate-500">
                      {testResult.latencyMs}ms latency
                    </span>
                  )}
                </div>
                <div className="text-[11px] leading-relaxed">
                  {testResult.ok
                    ? `Status: ${testResult.status || 'ok'}. Engines and Supabase communication active.`
                    : `${testResult.message || 'Failed to connect'}. Ensure the backend server and tunneling script are running.`}
                </div>
              </div>
            </div>
          )}

          {saveSuccess && (
            <div className="p-3 bg-emerald-50 border border-emerald-300 text-emerald-900 rounded-xl font-mono text-xs flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>Gateway URL applied successfully! Reconnecting dashboard...</span>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3.5 border-t border-[#CBD5E1] bg-[#F8FAFC] flex items-center justify-between">
          <button
            type="button"
            onClick={() => {
              setApiBaseUrl(null);
              onClose();
              if (typeof window !== 'undefined') window.location.reload();
            }}
            className="text-xs font-mono text-slate-500 hover:text-slate-800 underline cursor-pointer"
          >
            Reset to Default
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-3.5 py-2 text-xs font-mono text-slate-700 hover:bg-slate-200 rounded-xl transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={() => handleApply()}
              className="flex items-center gap-1.5 px-4 py-2 text-xs font-mono font-bold uppercase bg-black hover:bg-slate-800 text-white rounded-xl border border-black shadow-xs transition-all hover:-translate-y-0.5 cursor-pointer"
            >
              <span>Save &amp; Reconnect</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

