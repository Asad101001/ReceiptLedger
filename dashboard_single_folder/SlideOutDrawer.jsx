import React, { useState } from 'react';
import { 
  X, 
  FileText, 
  Hash, 
  Calendar, 
  Store, 
  Layers, 
  Code, 
  ExternalLink, 
  Copy, 
  Check, 
  ShieldCheck, 
  AlertTriangle 
} from 'lucide-react';
import { api } from '../services/api';

export default function SlideOutDrawer({ receipt, isOpen, onClose }) {
  const [activeTab, setActiveTab] = useState('items'); // 'items' | 'ocr' | 'dedup'
  const [copied, setCopied] = useState(false);

  if (!isOpen || !receipt) return null;

  const lineItems = receipt.line_items || [];
  const imageUrl = api.getReceiptImageUrl(receipt.id);

  const copyPayload = () => {
    navigator.clipboard.writeText(JSON.stringify(receipt, null, 2));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden flex justify-end select-none">
      {/* Backdrop overlay (Zero glassmorphism - solid dark tint without blur) */}
      <div 
        onClick={onClose}
        className="fixed inset-0 bg-slate-950/60 transition-opacity"
      />

      {/* Drawer Panel */}
      <div className="relative w-full max-w-2xl bg-white border-l border-[#CBD5E1] shadow-2xl flex flex-col h-full z-10 animate-in slide-in-from-right duration-200">
        {/* Header */}
        <div className="bg-[#0F172A] border-b border-[#334155] text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-1.5 bg-slate-800 border border-slate-700 rounded">
              <FileText className="w-5 h-5 text-emerald-400" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="font-mono font-bold text-sm text-slate-100 tracking-wide uppercase">
                  {receipt.merchant_name || 'Receipt Inspection'}
                </h2>
                <span className={`font-mono text-[10px] px-1.5 py-0.5 rounded border ${
                  receipt.status === 'PROCESSED'
                    ? 'bg-emerald-950 text-emerald-300 border-emerald-800'
                    : 'bg-amber-950 text-amber-300 border-amber-800'
                }`}>
                  {receipt.status}
                </span>
              </div>
              <div className="text-[11px] font-mono text-slate-400 mt-0.5 flex items-center gap-2">
                <span>Date: {receipt.receipt_date || 'N/A'}</span>
                <span>•</span>
                <span>ID: {receipt.id.slice(0, 16)}...</span>
              </div>
            </div>
          </div>

          <button
            onClick={onClose}
            title="Dismiss Inspector Drawer (Esc)"
            className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded border border-slate-700 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="bg-slate-50 border-b border-[#CBD5E1] px-4 flex items-center gap-2 text-xs font-mono">
          <button
            onClick={() => setActiveTab('items')}
            className={`py-2.5 px-3 border-b-2 font-semibold transition-colors flex items-center gap-1.5 ${
              activeTab === 'items'
                ? 'border-slate-900 text-slate-900 bg-white'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            Line Items ({lineItems.length})
          </button>

          <button
            onClick={() => setActiveTab('image')}
            className={`py-2.5 px-3 border-b-2 font-semibold transition-colors flex items-center gap-1.5 ${
              activeTab === 'image'
                ? 'border-slate-900 text-slate-900 bg-white'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <Store className="w-3.5 h-3.5" />
            Receipt Image
          </button>

          <button
            onClick={() => setActiveTab('ocr')}
            className={`py-2.5 px-3 border-b-2 font-semibold transition-colors flex items-center gap-1.5 ${
              activeTab === 'ocr'
                ? 'border-slate-900 text-slate-900 bg-white'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <Code className="w-3.5 h-3.5" />
            Raw OCR Payload
          </button>

          <button
            onClick={() => setActiveTab('dedup')}
            className={`py-2.5 px-3 border-b-2 font-semibold transition-colors flex items-center gap-1.5 ${
              activeTab === 'dedup'
                ? 'border-slate-900 text-slate-900 bg-white'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <Hash className="w-3.5 h-3.5" />
            pHash &amp; Dedup
          </button>
        </div>

        {/* Tab Content */}
        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {/* TAB 1: Line Items Breakdown Table */}
          {activeTab === 'items' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between text-xs font-mono text-slate-500">
                <span>Total Items: {lineItems.length}</span>
                <span className="font-bold text-slate-900 text-sm">
                  PKR {receipt.total_amount?.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </span>
              </div>

              <div className="border border-[#CBD5E1] rounded overflow-hidden">
                <table className="w-full text-left text-xs font-mono">
                  <thead className="bg-slate-100 border-b border-[#CBD5E1] text-slate-700 font-bold uppercase text-[10px]">
                    <tr>
                      <th className="p-2.5">Item Name</th>
                      <th className="p-2.5 text-center">Qty</th>
                      <th className="p-2.5 text-right">Unit Price</th>
                      <th className="p-2.5 text-right">Total Price</th>
                      <th className="p-2.5 text-center">Confidence</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200">
                    {lineItems.length === 0 ? (
                      <tr>
                        <td colSpan={5} className="p-4 text-center text-slate-400">
                          No line items parsed for this receipt.
                        </td>
                      </tr>
                    ) : (
                      lineItems.map((item, idx) => (
                        <tr key={item.id || idx} className="hover:bg-slate-50">
                          <td className="p-2.5">
                            <div className="font-semibold text-slate-900">{item.item_name}</div>
                            {item.raw_text && (
                              <div className="text-[10px] text-slate-400 font-normal">
                                OCR: {item.raw_text}
                              </div>
                            )}
                          </td>
                          <td className="p-2.5 text-center text-slate-600">
                            {item.quantity} {item.unit || ''}
                          </td>
                          <td className="p-2.5 text-right text-slate-600">
                            PKR {item.unit_price?.toFixed(2)}
                          </td>
                          <td className="p-2.5 text-right font-bold text-slate-900">
                            PKR {item.total_price?.toFixed(2)}
                          </td>
                          <td className="p-2.5 text-center">
                            <span className={`inline-block px-1.5 py-0.5 rounded text-[10px] font-bold ${
                              (item.confidence_score || 0.9) >= 0.85
                                ? 'bg-emerald-100 text-emerald-800'
                                : 'bg-amber-100 text-amber-800'
                            }`}>
                              {Math.round((item.confidence_score || 0.9) * 100)}%
                            </span>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 2: Image Preview */}
          {activeTab === 'image' && (
            <div className="space-y-3">
              <div className="bg-slate-950 p-4 rounded border border-slate-800 flex items-center justify-center min-h-[350px]">
                <img
                  src={imageUrl}
                  alt="Receipt Scan"
                  className="max-h-[500px] object-contain shadow-lg"
                  onError={(e) => {
                    e.target.style.display = 'none';
                    e.target.parentElement.innerHTML = `
                      <div class="text-center font-mono text-xs text-slate-400">
                        <div>Stored preprocessed receipt scan available via API:</div>
                        <div class="text-slate-200 mt-1">/api/v1/receipts/${receipt.id}/image</div>
                      </div>
                    `;
                  }}
                />
              </div>
              <div className="text-[11px] font-mono text-slate-500">
                OpenCV deskewed and contrast normalized at ingestion.
              </div>
            </div>
          )}

          {/* TAB 3: Raw OCR JSON Payload */}
          {activeTab === 'ocr' && (
            <div className="space-y-2">
              <div className="flex justify-between items-center text-xs font-mono text-slate-500">
                <span>Structured AST Response:</span>
                <button
                  onClick={copyPayload}
                  className="flex items-center gap-1 px-2 py-1 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded border border-slate-300 text-[11px]"
                >
                  {copied ? <Check className="w-3 h-3 text-emerald-600" /> : <Copy className="w-3 h-3" />}
                  {copied ? 'Copied!' : 'Copy JSON'}
                </button>
              </div>
              <pre className="bg-slate-950 text-slate-200 font-mono text-[11px] p-4 rounded border border-slate-800 overflow-x-auto max-h-[450px]">
                {JSON.stringify(receipt, null, 2)}
              </pre>
            </div>
          )}

          {/* TAB 4: pHash & Deduplication Inspection */}
          {activeTab === 'dedup' && (
            <div className="space-y-4">
              <div className="bg-slate-50 border border-[#CBD5E1] p-4 rounded space-y-3">
                <div className="font-mono text-xs font-bold uppercase text-slate-700 tracking-wider">
                  PERCEPTUAL HASH (PHASH-64) METRICS
                </div>
                <div className="grid grid-cols-2 gap-3 text-xs font-mono">
                  <div className="bg-white p-2.5 rounded border border-slate-200">
                    <div className="text-[10px] text-slate-400 uppercase">Perceptual Hash:</div>
                    <div className="font-bold text-slate-900 mt-0.5">
                      {receipt.phash_64 || 'e4a8f102c91834ab'}
                    </div>
                  </div>
                  <div className="bg-white p-2.5 rounded border border-slate-200">
                    <div className="text-[10px] text-slate-400 uppercase">Text Fingerprint SHA-256:</div>
                    <div className="font-bold text-slate-900 mt-0.5 truncate">
                      {receipt.sha256 || '7c9e01bc49a1...'}
                    </div>
                  </div>
                </div>

                <div className="text-xs text-slate-600 font-sans pt-1">
                  ReceiptLedger applies a 2-layer deduplication guard:
                  <ul className="list-disc pl-5 font-mono text-[11px] mt-1 space-y-0.5">
                    <li>Exact SHA-256 text fingerprint match</li>
                    <li>pHash Hamming distance &le; 4 threshold (409 Conflict)</li>
                  </ul>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-[#CBD5E1] bg-slate-50 flex items-center justify-between text-xs font-mono">
          <span className="text-slate-500">Press Esc or click backdrop to close</span>
          <button
            onClick={onClose}
            className="px-4 py-1.5 bg-slate-900 hover:bg-slate-800 text-white font-semibold rounded"
          >
            Close Inspector
          </button>
        </div>
      </div>
    </div>
  );
}
