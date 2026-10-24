import React, { useState, useRef } from 'react';
import { 
  X, 
  Upload, 
  FileText, 
  AlertTriangle, 
  CheckCircle2, 
  ArrowRight, 
  Sparkles, 
  Cpu, 
  ShieldAlert, 
  RefreshCw 
} from 'lucide-react';
import { api } from '../services/api';

export default function UploadReceiptModal({ isOpen, onClose, onUploadSuccess }) {
  const [file, setFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [ocrEngine, setOcrEngine] = useState('auto'); // 'auto' | 'gemini' | 'local'
  const [uploading, setUploading] = useState(false);
  const [pipelineStep, setPipelineStep] = useState(0); // 1: Preprocess, 2: pHash, 3: AI Vision, 4: Result
  const [conflictError, setConflictError] = useState(null);
  const [successResult, setSuccessResult] = useState(null);
  const fileInputRef = useRef(null);

  if (!isOpen) return null;

  const handleFileChange = (e) => {
    const selected = e.target.files?.[0];
    if (selected) {
      setFile(selected);
      setPreviewUrl(URL.createObjectURL(selected));
      setConflictError(null);
      setSuccessResult(null);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    const dropped = e.dataTransfer.files?.[0];
    if (dropped) {
      setFile(dropped);
      setPreviewUrl(URL.createObjectURL(dropped));
      setConflictError(null);
      setSuccessResult(null);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!file || uploading) return;

    setUploading(true);
    setConflictError(null);
    setSuccessResult(null);

    // Simulate animated pipeline progression
    setPipelineStep(1); // OpenCV Deskew
    setTimeout(() => setPipelineStep(2), 350); // pHash Dedup
    setTimeout(() => setPipelineStep(3), 700); // Gemini AI Vision

    try {
      const response = await api.uploadReceipt(file, ocrEngine);

      // Section 4 Pipeline Handling:
      if (response.status === 409) {
        // 409 Duplicate Conflict Banner!
        setConflictError({
          title: "409 CONFLICT: DUPLICATE RECEIPT DETECTED",
          message: "Exact SHA256 or pHash Hamming distance \u2264 4 matched an existing receipt in the ledger.",
          existingReceiptId: response.data?.existing_receipt_id || "41fd8d2a-e322-4f5f-aa37-ed65ffab5519",
          details: response.data?.detail || "Duplicate transaction rejected.",
        });
      } else if (response.ok) {
        setSuccessResult(response.data);
        if (onUploadSuccess) onUploadSuccess(response.data);
      } else {
        throw new Error(response.data?.detail || "Upload ingestion failed");
      }
    } catch (err) {
      console.error("Upload error:", err);
      setConflictError({
        title: "PIPELINE PROCESSING ERROR",
        message: err.message || "Failed to parse receipt image.",
      });
    } finally {
      setUploading(false);
      setPipelineStep(4);
    }
  };

  const resetModal = () => {
    setFile(null);
    setPreviewUrl(null);
    setConflictError(null);
    setSuccessResult(null);
    setPipelineStep(0);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden flex items-center justify-center p-4 select-none">
      {/* Backdrop (Zero glassmorphism) */}
      <div 
        onClick={onClose}
        className="fixed inset-0 bg-slate-950/70 transition-opacity"
      />

      {/* Modal Dialog */}
      <div className="relative w-full max-w-xl bg-white border border-[#CBD5E1] shadow-2xl rounded overflow-hidden z-10 flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="bg-[#0F172A] border-b border-[#334155] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="p-1 bg-blue-600 rounded">
              <Upload className="w-4 h-4 text-white" />
            </div>
            <div>
              <h2 className="font-mono font-bold text-sm tracking-wide uppercase text-slate-100">
                Receipt Ingestion &amp; Verification Pipeline
              </h2>
              <div className="text-[10px] font-mono text-slate-400">
                Section 4 Deduplication &amp; Gemini AI Vision Router
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

        {/* Modal Body */}
        <form onSubmit={handleSubmit} className="p-5 space-y-4 overflow-y-auto">
          {/* Section 4 Conflict Banner (Exact SHA256 OR pHash dist <= 4) */}
          {conflictError && (
            <div className="bg-red-50 border-2 border-red-500 p-4 rounded text-xs font-mono space-y-2">
              <div className="flex items-center gap-2 text-red-800 font-bold uppercase tracking-wider">
                <ShieldAlert className="w-5 h-5 text-red-600 shrink-0" />
                <span>{conflictError.title}</span>
              </div>
              <p className="text-red-700 font-sans">
                {conflictError.message}
              </p>
              {conflictError.existingReceiptId && (
                <div className="bg-white border border-red-200 p-2 rounded flex items-center justify-between">
                  <span className="text-slate-600 text-[11px]">Existing Record:</span>
                  <span className="font-bold text-slate-900 text-[11px] underline">
                    ID: {conflictError.existingReceiptId.slice(0, 16)}...
                  </span>
                </div>
              )}
            </div>
          )}

          {/* Ingestion Success Banner */}
          {successResult && (
            <div className="bg-emerald-50 border-2 border-emerald-500 p-4 rounded text-xs font-mono space-y-2">
              <div className="flex items-center gap-2 text-emerald-800 font-bold uppercase tracking-wider">
                <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
                <span>Receipt Ingested Successfully!</span>
              </div>
              <div className="text-emerald-900 font-sans">
                Status: <strong>{successResult.status}</strong> • Total: PKR {successResult.total_amount?.toFixed(2)}
              </div>
              <div className="text-[11px] text-slate-600">
                {successResult.status === 'PENDING_REVIEW'
                  ? 'Low confidence item flagged and added to Workspace A Human Review Queue.'
                  : 'Confidence \u2265 85%. Direct to Ingestion Ledger.'}
              </div>
            </div>
          )}

          {/* Visual Pipeline Steps (Section 4 Blueprint) */}
          <div className="bg-slate-50 border border-[#CBD5E1] p-3 rounded text-[11px] font-mono">
            <div className="text-slate-500 font-bold uppercase text-[10px] mb-2">
              INGESTION PIPELINE STAGES:
            </div>
            <div className="grid grid-cols-4 gap-1.5 text-center">
              <div className={`p-1.5 rounded border ${pipelineStep >= 1 ? 'bg-blue-100 border-blue-400 font-bold text-blue-900' : 'bg-white border-slate-200 text-slate-500'}`}>
                1. OpenCV Deskew
              </div>
              <div className={`p-1.5 rounded border ${pipelineStep >= 2 ? 'bg-blue-100 border-blue-400 font-bold text-blue-900' : 'bg-white border-slate-200 text-slate-500'}`}>
                2. pHash Dedup
              </div>
              <div className={`p-1.5 rounded border ${pipelineStep >= 3 ? 'bg-blue-100 border-blue-400 font-bold text-blue-900' : 'bg-white border-slate-200 text-slate-500'}`}>
                3. Gemini Vision
              </div>
              <div className={`p-1.5 rounded border ${pipelineStep >= 4 ? 'bg-blue-100 border-blue-400 font-bold text-blue-900' : 'bg-white border-slate-200 text-slate-500'}`}>
                4. Route to Desk
              </div>
            </div>
          </div>

          {/* Dropzone */}
          <div
            onDragOver={(e) => e.preventDefault()}
            onDrop={handleDrop}
            onClick={() => fileInputRef.current?.click()}
            className="border-2 border-dashed border-[#CBD5E1] hover:border-slate-800 p-6 rounded bg-slate-50 flex flex-col items-center justify-center text-center cursor-pointer transition-colors"
          >
            <input
              ref={fileInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              onChange={handleFileChange}
              className="hidden"
            />
            {previewUrl ? (
              <div className="space-y-2">
                <img
                  src={previewUrl}
                  alt="Receipt Preview"
                  className="max-h-48 object-contain border border-[#CBD5E1] rounded shadow-sm mx-auto"
                />
                <div className="font-mono text-xs text-slate-700 font-bold">
                  {file?.name} ({(file.size / 1024).toFixed(1)} KB)
                </div>
                <div className="text-[11px] text-blue-600 font-mono">
                  Click to replace image
                </div>
              </div>
            ) : (
              <div className="space-y-2">
                <div className="w-10 h-10 bg-slate-200 border border-slate-300 rounded-full flex items-center justify-center mx-auto text-slate-600">
                  <Upload className="w-5 h-5" />
                </div>
                <div className="font-mono text-xs font-bold text-slate-800 uppercase">
                  Drag &amp; drop receipt image, or browse
                </div>
                <div className="text-[11px] font-mono text-slate-500">
                  Supports JPEG, PNG, WebP up to 10MB
                </div>
              </div>
            )}
          </div>

          {/* OCR Engine Picker */}
          <div>
            <label className="block text-xs font-mono font-semibold text-slate-700 uppercase mb-1.5">
              OCR &amp; Vision Engine:
            </label>
            <div className="grid grid-cols-3 gap-2 font-mono text-xs">
              <button
                type="button"
                onClick={() => setOcrEngine('auto')}
                className={`p-2 rounded border text-left ${
                  ocrEngine === 'auto'
                    ? 'bg-slate-900 text-white border-slate-900 font-bold'
                    : 'bg-white text-slate-700 border-[#CBD5E1] hover:bg-slate-100'
                }`}
              >
                <div>Auto (Hybrid)</div>
                <div className="text-[10px] opacity-75">Gemini + Vision</div>
              </button>

              <button
                type="button"
                onClick={() => setOcrEngine('gemini')}
                className={`p-2 rounded border text-left ${
                  ocrEngine === 'gemini'
                    ? 'bg-slate-900 text-white border-slate-900 font-bold'
                    : 'bg-white text-slate-700 border-[#CBD5E1] hover:bg-slate-100'
                }`}
              >
                <div>Gemini AI</div>
                <div className="text-[10px] opacity-75">3.5 Flash-Lite</div>
              </button>

              <button
                type="button"
                onClick={() => setOcrEngine('local')}
                className={`p-2 rounded border text-left ${
                  ocrEngine === 'local'
                    ? 'bg-slate-900 text-white border-slate-900 font-bold'
                    : 'bg-white text-slate-700 border-[#CBD5E1] hover:bg-slate-100'
                }`}
              >
                <div>Local OCR</div>
                <div className="text-[10px] opacity-75">Tesseract / EasyOCR</div>
              </button>
            </div>
          </div>

          {/* Submit / Action Buttons */}
          <div className="pt-3 border-t border-[#CBD5E1] flex items-center justify-between">
            <button
              type="button"
              onClick={resetModal}
              className="text-xs font-mono text-slate-600 hover:text-slate-900"
            >
              Reset Form
            </button>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={onClose}
                className="px-3 py-1.5 border border-[#CBD5E1] text-xs font-mono text-slate-700 rounded hover:bg-slate-100"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={!file || uploading}
                className="flex items-center gap-1.5 px-4 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-mono text-xs font-bold rounded border border-blue-700 transition-colors cursor-pointer"
              >
                {uploading ? (
                  <>
                    <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                    <span>Processing Pipeline...</span>
                  </>
                ) : (
                  <>
                    <ArrowRight className="w-3.5 h-3.5" />
                    <span>Run Ingestion Pipeline</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
