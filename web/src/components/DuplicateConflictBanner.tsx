import React from 'react';
import { ShieldAlert, ExternalLink, X } from 'lucide-react';
import { useConsoleStore } from '../store/useConsoleStore';

interface DuplicateConflictBannerProps {
  onViewReceipt: (receiptId: string) => void;
}

export const DuplicateConflictBanner: React.FC<DuplicateConflictBannerProps> = ({
  onViewReceipt,
}) => {
  const { conflictAlert, setConflictAlert } = useConsoleStore();

  if (!conflictAlert) return null;

  return (
    <div className="bg-amber-50 border-y sm:border border-amber-300 sm:rounded p-3 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 font-mono text-xs text-amber-950 select-none animate-in fade-in duration-150">
      <div className="flex items-center gap-2.5">
        <div className="p-1.5 bg-amber-200 border border-amber-300 rounded text-amber-800 flex-shrink-0">
          <ShieldAlert className="w-4 h-4" />
        </div>
        <div>
          <div className="font-bold text-amber-900">
            HTTP 409 Conflict: Duplicate Receipt Detected
          </div>
          <div className="text-[11px] text-amber-800 mt-0.5 font-sans">
            {conflictAlert.message ||
              `An identical image or matching text fingerprint already exists in the ledger.`}
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
        <button
          onClick={() => {
            onViewReceipt(conflictAlert.existingReceiptId);
          }}
          className="flex items-center gap-1 bg-amber-900 hover:bg-amber-800 text-white px-2.5 py-1 rounded text-xs font-semibold transition-colors cursor-pointer"
        >
          <span>View Matched Receipt</span>
          <ExternalLink className="w-3 h-3" />
        </button>

        <button
          onClick={() => setConflictAlert(null)}
          title="Dismiss Banner"
          className="p-1 text-amber-700 hover:text-amber-900 transition-colors cursor-pointer"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
