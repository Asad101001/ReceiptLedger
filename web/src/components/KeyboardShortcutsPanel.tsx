import React from 'react';
import { X, Keyboard } from 'lucide-react';

interface KeyboardShortcutsPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

export const KeyboardShortcutsPanel: React.FC<KeyboardShortcutsPanelProps> = ({
  isOpen,
  onClose,
}) => {
  if (!isOpen) return null;

  const shortcuts = [
    {
      key: 'Enter / Return',
      context: 'Review Desk Table',
      action: '1-Click Approve active item (action: "ACCEPTED") and auto-focus next row',
    },
    {
      key: 'Ctrl+S / Cmd+S',
      context: 'Review Desk Table',
      action: 'Save inline edits on candidate name, qty, or price (action: "EDITED")',
    },
    {
      key: 'Tab',
      context: 'Review Desk Row',
      action: 'Advance focus between candidate item name, quantity, unit, and price fields',
    },
    {
      key: 'Shift + Tab',
      context: 'Review Desk Row',
      action: 'Move backward to previous field',
    },
    {
      key: '↑ / ↓ or J / K',
      context: 'Audit Ledger Grid',
      action: 'Select previous / next receipt row',
    },
    {
      key: 'Space',
      context: 'Audit Ledger Row',
      action: 'Open Slide-Out Inspector Drawer for selected receipt',
    },
    {
      key: 'Esc',
      context: 'Modal / Drawer',
      action: 'Dismiss Slide-Out Inspector Drawer or cancel inline editing',
    },
    {
      key: '/',
      context: 'Global',
      action: 'Jump focus directly to Ingestion Ledger Search input',
    },
    {
      key: '?',
      context: 'Global',
      action: 'Toggle this keyboard shortcuts cheat sheet panel',
    },
  ];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Keyboard Shortcuts Cheat Sheet"
      className="fixed inset-0 z-50 overflow-hidden flex justify-end select-none"
    >
      {/* Backdrop (Solid dark opacity, Zero glass, no blur) */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-slate-950/70 transition-opacity"
        aria-hidden="true"
      />

      {/* Slide-out drawer panel */}
      <div className="relative w-full max-w-xl bg-white border-l border-[#CBD5E1] flex flex-col h-full z-10 animate-in slide-in-from-right duration-150">
        {/* Header */}
        <div className="bg-[#0F172A] border-b border-[#334155] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="p-1.5 bg-slate-800 border border-slate-700 rounded">
              <Keyboard className="w-5 h-5 text-amber-400" />
            </div>
            <div>
              <h2 className="font-mono font-bold text-sm tracking-wide uppercase text-slate-100">
                Desktop Keyboard Ergonomics &amp; Shortcuts
              </h2>
              <p className="font-mono text-xs text-slate-400 mt-0.5">
                Design Brief § 5 Cheat Sheet
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded border border-slate-700 transition-colors cursor-pointer"
            title="Dismiss Shortcuts (Esc)"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Shortcuts Table */}
        <div className="flex-1 overflow-y-auto p-5">
          <div className="border border-[#CBD5E1] rounded overflow-hidden">
            <table className="w-full text-left text-xs font-mono">
              <thead className="bg-slate-100 border-b border-[#CBD5E1] text-slate-700 font-bold uppercase text-[10px]">
                <tr>
                  <th className="p-2.5">Shortcut</th>
                  <th className="p-2.5">Context</th>
                  <th className="p-2.5">Action / Result</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {shortcuts.map((sc, i) => (
                  <tr key={i} className="hover:bg-slate-50">
                    <td className="p-2.5 whitespace-nowrap">
                      <kbd className="font-bold text-slate-900 bg-white border border-slate-300 px-2 py-0.5 rounded shadow-none text-xs">
                        {sc.key}
                      </kbd>
                    </td>
                    <td className="p-2.5 text-slate-500 whitespace-nowrap font-semibold text-[11px]">
                      {sc.context}
                    </td>
                    <td className="p-2.5 text-slate-800 leading-relaxed font-sans text-xs">
                      {sc.action}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="mt-4 p-3 bg-slate-50 border border-slate-200 rounded text-xs font-mono text-slate-600 space-y-1">
            <div className="font-bold text-slate-800 uppercase text-[11px]">
              Scope-Aware Hotkey Handling:
            </div>
            <p className="font-sans text-xs text-slate-600">
              Navigation keys (J, K, Space, /) are disabled while typing in text inputs or triage
              fields to prevent accidental focus loss.
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-[#CBD5E1] bg-slate-50 flex items-center justify-between text-xs font-mono">
          <span className="text-slate-500">Press Esc to dismiss cheat sheet</span>
          <button
            onClick={onClose}
            className="px-4 py-1.5 bg-slate-900 hover:bg-slate-800 text-white font-semibold rounded cursor-pointer"
          >
            Close Panel
          </button>
        </div>
      </div>
    </div>
  );
};
