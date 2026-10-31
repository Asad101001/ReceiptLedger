import React, { useState } from 'react';
import { X, Palette } from 'lucide-react';

interface DesignShowcaseModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const DesignShowcaseModal: React.FC<DesignShowcaseModalProps> = ({ isOpen, onClose }) => {
  const [selectedScreen, setSelectedScreen] = useState<'capture' | 'ledger' | 'review' | 'settings'>('capture');

  if (!isOpen) return null;

  const screens = [
    {
      id: 'capture' as const,
      label: 'Receipt Capture',
      desc: 'Mobile viewfinder with live edge detection & crop guidance',
      src: '/mockups/capture_screen.png',
      icon: '/icons/capture_icon.svg',
    },
    {
      id: 'ledger' as const,
      label: 'Ingestion Ledger',
      desc: 'Paginated expense records with Pakistani Rupee calculations',
      src: '/mockups/ledger_screen.png',
      icon: '/icons/ledger_icon.svg',
    },
    {
      id: 'review' as const,
      label: 'Human Review',
      desc: 'Confidence-threshold verification for ambiguous line items (<85%)',
      src: '/mockups/review_screen.png',
      icon: '/icons/review_icon.svg',
    },
    {
      id: 'settings' as const,
      label: 'Engine Settings',
      desc: 'OCR engine selection, offline mode, and API gateway routes',
      src: '/mockups/settings_screen.png',
      icon: '/icons/settings_icon.svg',
    },
  ];

  const activeScreen = screens.find((s) => s.id === selectedScreen) || screens[0];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="UI Mockups and Design System"
      className="fixed inset-0 z-50 overflow-hidden flex items-center justify-center p-3 sm:p-6 select-none animate-in fade-in-50 duration-150"
    >
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-slate-950/75 transition-opacity"
        aria-hidden="true"
      />

      {/* Modal Dialog */}
      <div className="relative w-full max-w-4xl bg-white border border-[#CBD5E1] rounded-2xl shadow-2xl z-10 flex flex-col max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="bg-[#0F172A] border-b border-[#334155] text-white p-4 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-white/10 border border-white/10 flex items-center justify-center p-1">
              <img src="/icons/app_icon.svg" alt="App Icon" className="w-5 h-5 invert" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-mono font-bold text-xs uppercase tracking-wide text-white">
                  ReceiptLedger UI Design System &amp; Mobile Mockups
                </h3>
                <span className="font-mono text-[9px] bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 px-1.5 py-0.2 rounded font-semibold">
                  Sprint Deliverables
                </span>
              </div>
              <p className="text-[10px] text-slate-400 font-mono">
                Official design benchmarks, screen workflows, and mobile interface assets
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content Body */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 grid grid-cols-1 md:grid-cols-12 gap-6 font-mono text-xs">
          {/* Left: Screen Selectors & Metadata */}
          <div className="md:col-span-5 space-y-4">
            <div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-2">
                Mobile App Screens (Sprint 1)
              </span>
              <div className="space-y-2">
                {screens.map((s) => {
                  const isSelected = s.id === selectedScreen;
                  return (
                    <button
                      key={s.id}
                      type="button"
                      onClick={() => setSelectedScreen(s.id)}
                      className={`w-full text-left p-3 rounded-xl border transition-all duration-150 flex items-start gap-3 cursor-pointer ${
                        isSelected
                          ? 'bg-black text-white border-black shadow-xs -translate-y-0.5'
                          : 'bg-[#F8FAFC] text-slate-800 border-[#CBD5E1] hover:bg-white hover:border-slate-400'
                      }`}
                    >
                      <div className={`p-1.5 rounded-lg shrink-0 ${isSelected ? 'bg-white/20' : 'bg-white border border-[#CBD5E1]'}`}>
                        <img src={s.icon} alt={s.label} className={`w-4 h-4 ${isSelected ? 'invert' : ''}`} />
                      </div>
                      <div className="min-w-0">
                        <div className="font-bold text-xs">{s.label}</div>
                        <div className={`text-[10px] line-clamp-2 mt-0.5 ${isSelected ? 'text-slate-300' : 'text-slate-500'}`}>
                          {s.desc}
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Design Principles Reference */}
            <div className="bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl p-3.5 space-y-2 text-[11px] text-slate-600">
              <div className="font-bold text-slate-900 uppercase text-[10px] flex items-center gap-1.5">
                <Palette className="w-3.5 h-3.5 text-slate-700" />
                <span>Aesthetic &amp; Typography Specs</span>
              </div>
              <ul className="space-y-1 text-slate-600 list-disc list-inside">
                <li>Primary typeface: JetBrains Mono + Inter</li>
                <li>Monochrome baseline: Pure black &amp; crisp white</li>
                <li>Accent: Emerald Green &amp; Amber Alert</li>
                <li>Zero-blur flat opacity with solid borders</li>
              </ul>
            </div>
          </div>

          {/* Right: Screen Mockup Preview */}
          <div className="md:col-span-7 flex flex-col items-center justify-center bg-slate-950 p-6 rounded-2xl border border-slate-800 relative min-h-[380px]">
            <div className="relative max-h-[500px] flex items-center justify-center">
              <img
                src={activeScreen.src}
                alt={activeScreen.label}
                className="max-h-[460px] w-auto object-contain rounded-xl shadow-2xl border border-slate-800"
              />
            </div>
            <div className="mt-3 text-center text-slate-400 text-[11px]">
              <span>{activeScreen.label} • Mobile UI Deliverable</span>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="bg-[#F8FAFC] border-t border-[#CBD5E1] px-5 py-3 flex items-center justify-between text-xs font-mono shrink-0">
          <span className="text-slate-500 text-[11px]">
            Assets sourced from <code className="bg-slate-200 px-1 py-0.5 rounded">UI mockups/mockups/core/</code>
          </span>
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-1.5 bg-black hover:bg-slate-800 text-white rounded-lg font-bold transition-all duration-150 hover:-translate-y-0.5 cursor-pointer"
          >
            Close Preview
          </button>
        </div>
      </div>
    </div>
  );
};
