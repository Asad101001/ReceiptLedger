import React from 'react';
import { X, Command, Keyboard } from 'lucide-react';

export default function KeyboardShortcutsModal({ isOpen, onClose }) {
  if (!isOpen) return null;

  const shortcuts = [
    {
      key: 'Enter / Return',
      context: 'Review Desk Table',
      action: '1-Click Approve active item (action: "ACCEPTED") and auto-focus next row',
    },
    {
      key: 'Ctrl + S / Cmd + S',
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
      key: '/ (Forward Slash)',
      context: 'Global',
      action: 'Jump focus directly to Ingestion Ledger Search input',
    },
  ];

  return (
    <div className="fixed inset-0 z-50 overflow-hidden flex items-center justify-center p-4 select-none">
      {/* Backdrop */}
      <div 
        onClick={onClose}
        className="fixed inset-0 bg-slate-950/70 transition-opacity"
      />

      {/* Modal Dialog */}
      <div className="relative w-full max-w-2xl bg-white border border-[#CBD5E1] shadow-2xl rounded overflow-hidden z-10 flex flex-col">
        {/* Header */}
        <div className="bg-[#0F172A] border-b border-[#334155] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="p-1.5 bg-slate-800 border border-slate-700 rounded">
              <Keyboard className="w-4 h-4 text-emerald-400" />
            </div>
            <div>
              <h2 className="font-mono font-bold text-sm tracking-wide uppercase text-slate-100">
                Desktop Keyboard Ergonomics &amp; Shortcuts Cheat Sheet
              </h2>
              <div className="text-[10px] font-mono text-slate-400">
                Section 5 Operational Efficiency Blueprint
              </div>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded border border-slate-700 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Shortcuts Table */}
        <div className="p-5 overflow-y-auto max-h-[70vh]">
          <div className="border border-[#CBD5E1] rounded overflow-hidden">
            <table className="w-full text-left text-xs font-mono">
              <thead className="bg-slate-100 border-b border-[#CBD5E1] text-slate-700 font-bold uppercase text-[10px]">
                <tr>
                  <th className="py-2.5 px-3">Shortcut</th>
                  <th className="py-2.5 px-3">Context</th>
                  <th className="py-2.5 px-3">Action / Result</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {shortcuts.map((sc, idx) => (
                  <tr key={idx} className="hover:bg-slate-50">
                    <td className="py-2.5 px-3 whitespace-nowrap">
                      <kbd className="font-bold text-slate-900 bg-slate-100 border border-slate-300 px-2 py-0.5 rounded text-[11px]">
                        {sc.key}
                      </kbd>
                    </td>
                    <td className="py-2.5 px-3 text-slate-600 whitespace-nowrap font-semibold">
                      {sc.context}
                    </td>
                    <td className="py-2.5 px-3 text-slate-800">
                      {sc.action}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="mt-4 p-3 bg-slate-50 border border-[#CBD5E1] rounded text-[11px] font-mono text-slate-600 flex items-center justify-between">
            <span>Press <kbd>Esc</kbd> anytime to dismiss this modal.</span>
            <span className="text-slate-400">Zero Mouse Drag Required</span>
          </div>
        </div>

        {/* Footer */}
        <div className="p-3 bg-slate-100 border-t border-[#CBD5E1] text-right">
          <button
            onClick={onClose}
            className="px-4 py-1.5 bg-slate-900 hover:bg-slate-800 text-white font-mono text-xs font-bold rounded"
          >
            Got It (Esc)
          </button>
        </div>
      </div>
    </div>
  );
}
