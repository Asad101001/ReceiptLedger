import React, { useState } from 'react';
import {
  X,
  Upload,
  FileImage,
  AlertTriangle,
  CheckCircle2,
} from 'lucide-react';
import { api } from '../api/client';
import { ProjectIcon } from './ui/ProjectIcon';
import { useConsoleStore } from '../store/useConsoleStore';

interface UploadReceiptDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onUploadSuccess: () => void;
}

export const UploadReceiptDrawer: React.FC<UploadReceiptDrawerProps> = ({
  isOpen,
  onClose,
  onUploadSuccess,
}) => {
  const { setConflictAlert } = useConsoleStore();
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [ocrEngine, setOcrEngine] = useState<string>('auto');
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedFile(e.target.files[0]);
      setErrorMsg(null);
      setSuccessMsg(null);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      setSelectedFile(e.dataTransfer.files[0]);
      setErrorMsg(null);
      setSuccessMsg(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedFile) {
      setErrorMsg('Please select a receipt image (JPEG, PNG, WEBP).');
      return;
    }

    setIsUploading(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const res = await api.uploadReceipt(selectedFile, ocrEngine);

      if (res.status === 409) {
        // 409 Conflict: Duplicate Receipt
        const dupData = res.data as {
          receipt_id?: string;
          status?: string;
          merchant_name?: string;
          detail?: string;
        };
        const dupId = dupData.receipt_id || 'duplicate-receipt';
        setConflictAlert({
          existingReceiptId: dupId,
          message:
            dupData.detail ||
            `409 Conflict: Duplicate receipt detected (Exact SHA-256 or pHash <= 4 bits). Matched Receipt: ${dupId}`,
        });
        setErrorMsg(
          `409 Conflict: This receipt matches an existing ledger record (${dupId.slice(0, 12)}...).`
        );
      } else if (!res.ok) {
        const errorData = res.data as { detail?: string };
        setErrorMsg(errorData?.detail || `Upload failed with status ${res.status}`);
      } else {
        setSuccessMsg('Receipt successfully ingested and processed!');
        setSelectedFile(null);
        setTimeout(() => {
          onUploadSuccess();
          onClose();
        }, 1200);
      }
    } catch (err: unknown) {
      if (err instanceof Error) {
        setErrorMsg(err.message);
      } else {
        setErrorMsg('Receipt processing failed.');
      }
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Upload Receipt Image"
      className="fixed inset-0 z-50 overflow-hidden flex justify-end select-none"
    >
      {/* Backdrop (Solid dark opacity, Zero glass, no blur) */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-slate-950/70 transition-opacity"
        aria-hidden="true"
      />

      {/* Slide-out drawer panel */}
      <div className="relative w-full max-w-lg bg-white border-l border-[#CBD5E1] flex flex-col h-full z-10 animate-in slide-in-from-right duration-150">
        {/* Header */}
        <div className="bg-[#0F172A] border-b border-[#334155] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="p-1.5 bg-slate-800 border border-slate-700 rounded flex items-center justify-center">
              <ProjectIcon name="capture" className="w-5 h-5 text-emerald-400" />
            </div>
            <div>
              <h2 className="font-mono font-bold text-sm tracking-wide uppercase text-slate-100">
                Receipt Ingestion Gateway
              </h2>
              <p className="font-mono text-xs text-slate-400 mt-0.5">
                POST /api/v1/receipts/upload
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded border border-slate-700 transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-5 space-y-4">
          {errorMsg && (
            <div className="bg-red-50 border border-red-300 text-red-900 text-xs font-mono p-3 rounded flex items-start gap-2">
              <AlertTriangle className="w-4 h-4 text-red-600 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <span>{errorMsg}</span>
              </div>
            </div>
          )}

          {successMsg && (
            <div className="bg-emerald-50 border border-emerald-300 text-emerald-900 text-xs font-mono p-3 rounded flex items-start gap-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0 mt-0.5" />
              <span>{successMsg}</span>
            </div>
          )}

          {/* Drag & Drop File Upload Area */}
          <div
            onDragOver={(e) => e.preventDefault()}
            onDrop={handleDrop}
            className="border-2 border-dashed border-[#CBD5E1] hover:border-slate-800 bg-slate-50 p-6 rounded text-center cursor-pointer transition-colors"
          >
            <FileImage className="w-10 h-10 text-slate-400 mx-auto mb-2" />
            <div className="font-mono text-xs font-bold text-slate-800 uppercase">
              {selectedFile ? selectedFile.name : 'Select or drop receipt image'}
            </div>
            <div className="font-mono text-[11px] text-slate-500 mt-1">
              Supports JPEG, PNG, WEBP (Max 10MB)
            </div>
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              onChange={handleFileChange}
              className="mt-3 text-xs font-mono block mx-auto text-slate-600 file:mr-2 file:py-1 file:px-3 file:rounded file:border file:border-slate-300 file:text-xs file:font-mono file:bg-white file:text-slate-700 cursor-pointer"
            />
          </div>

          {/* Engine Selection */}
          <div>
            <label className="block text-xs font-mono font-bold uppercase text-slate-700 mb-1">
              OCR &amp; Extraction Engine
            </label>
            <select
              value={ocrEngine}
              onChange={(e) => setOcrEngine(e.target.value)}
              className="w-full bg-white font-mono text-xs text-slate-900 border border-[#CBD5E1] p-2 rounded outline-none"
            >
              <option value="auto">Auto (Gemini AI Vision + Hybrid Fallback)</option>
              <option value="gemini">Gemini 3.5 Flash-Lite Vision Only</option>
              <option value="local">Local OCR (Tesseract / EasyOCR)</option>
            </select>
          </div>

          {/* Pipeline Info */}
          <div className="p-3 bg-slate-50 border border-slate-200 rounded text-xs font-mono text-slate-600 space-y-1">
            <div className="font-bold text-slate-800 uppercase text-[11px]">
              Ingestion Pipeline Stages:
            </div>
            <ol className="list-decimal pl-4 space-y-0.5 text-[11px]">
              <li>OpenCV Preprocessing &amp; Deskew</li>
              <li>Perceptual Hashing (64-bit DCT pHash)</li>
              <li>Deduplication Guard (409 Conflict if pHash &le; 4)</li>
              <li>OCR Extraction &amp; NLP Product Normalization</li>
              <li>Review Queue Flagging for Items &lt; 85% Confidence</li>
            </ol>
          </div>

          <button
            type="submit"
            disabled={isUploading || !selectedFile}
            className="w-full flex items-center justify-center gap-2 bg-slate-900 hover:bg-slate-800 text-white font-mono text-xs font-bold uppercase py-2.5 px-4 rounded border border-slate-900 transition-colors disabled:opacity-40 cursor-pointer"
          >
            {isUploading ? (
              <span>Running Pipeline Ingestion...</span>
            ) : (
              <>
                <Upload className="w-4 h-4" />
                <span>Ingest &amp; Extract Receipt</span>
              </>
            )}
          </button>
        </form>

        {/* Footer */}
        <div className="p-4 border-t border-[#CBD5E1] bg-slate-50 flex items-center justify-between text-xs font-mono">
          <span className="text-slate-500">Press Esc to dismiss</span>
          <button
            onClick={onClose}
            className="px-4 py-1.5 bg-white hover:bg-slate-100 border border-[#CBD5E1] text-slate-700 font-semibold rounded cursor-pointer"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
};
