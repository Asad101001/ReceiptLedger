import React from 'react';
import { AlertCircle, RefreshCw, WifiOff } from 'lucide-react';

interface NetworkErrorBannerProps {
  message?: string;
  onRetry: () => void;
  isRetrying?: boolean;
  onSwitchToMockMode?: () => void;
}

export const NetworkErrorBanner: React.FC<NetworkErrorBannerProps> = ({
  message,
  onRetry,
  isRetrying,
  onSwitchToMockMode,
}) => {
  return (
    <div className="bg-red-50 border border-red-300 p-3 rounded flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2.5 font-mono text-xs text-red-900 select-none">
      <div className="flex items-center gap-2">
        <AlertCircle className="w-4 h-4 text-red-600 flex-shrink-0" />
        <span>
          {message || 'Network connection failed or backend gateway is unreachable.'}
        </span>
      </div>

      <div className="flex items-center gap-2">
        {onSwitchToMockMode && (
          <button
            type="button"
            onClick={onSwitchToMockMode}
            className="flex items-center gap-1.5 bg-slate-900 hover:bg-black text-white font-mono text-xs font-semibold px-2.5 py-1 rounded transition-colors cursor-pointer"
          >
            <WifiOff className="w-3.5 h-3.5 text-amber-400" />
            <span>Switch to Offline Dev Mode</span>
          </button>
        )}
        <button
          type="button"
          onClick={onRetry}
          disabled={isRetrying}
          className="flex items-center gap-1.5 bg-red-800 hover:bg-red-700 disabled:opacity-50 text-white font-mono text-xs font-semibold px-2.5 py-1 rounded transition-colors cursor-pointer"
        >
          <RefreshCw className={`w-3 h-3 ${isRetrying ? 'animate-spin' : ''}`} />
          <span>Retry Request</span>
        </button>
      </div>
    </div>
  );
};
