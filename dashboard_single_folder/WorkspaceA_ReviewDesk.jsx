import React, { useState, useEffect, useRef } from 'react';
import { 
  ZoomIn, 
  ZoomOut, 
  RotateCcw, 
  Maximize2, 
  Check, 
  Save, 
  ChevronRight, 
  ChevronLeft, 
  Scan, 
  AlertCircle, 
  CheckCircle2, 
  Sparkles,
  Layers,
  Crop
} from 'lucide-react';
import { api } from '../services/api';

export default function WorkspaceA_ReviewDesk({ 
  queueItems = [], 
  onItemResolved, 
  onRefreshQueue,
  activeQueueIndex = 0,
  setActiveQueueIndex
}) {
  const [zoom, setZoom] = useState(1.5);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [viewMode, setViewMode] = useState('full'); // 'full' | 'crop'
  const [resolving, setResolving] = useState(false);
  const [statusMessage, setStatusMessage] = useState(null);

  // Active review item
  const currentItem = queueItems[activeQueueIndex] || null;

  // Form State
  const [formData, setFormData] = useState({
    confirmed_name: '',
    confirmed_quantity: 1,
    confirmed_unit: 'pcs',
    confirmed_unit_price: 0,
    confirmed_total_price: 0,
  });

  const nameInputRef = useRef(null);
  const canvasRef = useRef(null);

  // Sync form data whenever active item changes
  useEffect(() => {
    if (currentItem) {
      const li = currentItem.line_item || {};
      const candidateName = currentItem.candidate_name || currentItem.candidate_text || li.item_name || '';
      const qty = li.quantity !== undefined ? li.quantity : 1;
      const unit = li.unit || 'pcs';
      const uPrice = li.unit_price !== undefined ? li.unit_price : 0;
      const tPrice = li.total_price !== undefined ? li.total_price : qty * uPrice;

      setFormData({
        confirmed_name: candidateName,
        confirmed_quantity: qty,
        confirmed_unit: unit,
        confirmed_unit_price: uPrice,
        confirmed_total_price: tPrice,
      });

      // Auto-focus item candidate name input for keyboard ergonomics
      setTimeout(() => {
        if (nameInputRef.current) {
          nameInputRef.current.focus();
          nameInputRef.current.select();
        }
      }, 50);

      // Reset pan/zoom
      setPan({ x: 0, y: -20 });
      setZoom(1.5);
    }
  }, [currentItem, activeQueueIndex]);

  // Recalculate total price when qty or unit price changes
  const handleQtyChange = (e) => {
    const qty = parseFloat(e.target.value) || 0;
    setFormData((prev) => ({
      ...prev,
      confirmed_quantity: qty,
      confirmed_total_price: round(qty * prev.confirmed_unit_price),
    }));
  };

  const handlePriceChange = (e) => {
    const uPrice = parseFloat(e.target.value) || 0;
    setFormData((prev) => ({
      ...prev,
      confirmed_unit_price: uPrice,
      confirmed_total_price: round(prev.confirmed_quantity * uPrice),
    }));
  };

  const round = (val) => Math.round((val + Number.EPSILON) * 100) / 100;

  // Zoom controls (100% to 400%)
  const handleZoomIn = () => setZoom((z) => Math.min(4.0, round(z + 0.25)));
  const handleZoomOut = () => setZoom((z) => Math.max(1.0, round(z - 0.25)));
  const handleZoomReset = () => {
    setZoom(1.0);
    setPan({ x: 0, y: 0 });
  };
  const handleZoomFit = () => {
    setZoom(1.5);
    setPan({ x: 0, y: -20 });
  };

  // Mouse pan handlers
  const handleMouseDown = (e) => {
    if (e.button !== 0) return; // Primary click only
    setIsDragging(true);
    setDragStart({ x: e.clientX - pan.x, y: e.clientY - pan.y });
  };

  const handleMouseMove = (e) => {
    if (!isDragging) return;
    setPan({
      x: e.clientX - dragStart.x,
      y: e.clientY - dragStart.y,
    });
  };

  const handleMouseUp = () => setIsDragging(false);

  // 1-Click Accept (Enter)
  const handleAccept = async () => {
    if (!currentItem || resolving) return;
    setResolving(true);
    try {
      const queueId = currentItem.id || currentItem.queue_id;
      await api.resolveReviewItem(queueId, {
        confirmed_name: formData.confirmed_name,
        action: 'ACCEPTED',
      });
      showStatus('ACCEPTED', 'Approved item and verified in ledger.');
      if (onItemResolved) onItemResolved(queueId, 'ACCEPTED');
    } catch (err) {
      console.error('Accept error:', err);
      showStatus('ERROR', err.message || 'Failed to accept item');
    } finally {
      setResolving(false);
    }
  };

  // Save Edits (Ctrl+S)
  const handleSaveEdits = async () => {
    if (!currentItem || resolving) return;
    setResolving(true);
    try {
      const queueId = currentItem.id || currentItem.queue_id;
      await api.resolveReviewItem(queueId, {
        confirmed_name: formData.confirmed_name,
        confirmed_quantity: formData.confirmed_quantity,
        confirmed_unit: formData.confirmed_unit,
        confirmed_unit_price: formData.confirmed_unit_price,
        confirmed_total_price: formData.confirmed_total_price,
        action: 'EDITED',
      });
      showStatus('EDITED', 'Saved corrected candidate fields to line item.');
      if (onItemResolved) onItemResolved(queueId, 'EDITED');
    } catch (err) {
      console.error('Save edits error:', err);
      showStatus('ERROR', err.message || 'Failed to save edits');
    } finally {
      setResolving(false);
    }
  };

  const showStatus = (type, msg) => {
    setStatusMessage({ type, msg });
    setTimeout(() => setStatusMessage(null), 3000);
  };

  // Bounding box calculation for active line item
  const li = currentItem?.line_item || {};
  const bbox = li.bbox || { ymin: 0.35, xmin: 0.08, ymax: 0.45, xmax: 0.92 };
  const bboxTop = `${(bbox.ymin || 0.35) * 100}%`;
  const bboxLeft = `${(bbox.xmin || 0.08) * 100}%`;
  const bboxHeight = `${((bbox.ymax || 0.45) - (bbox.ymin || 0.35)) * 100}%`;
  const bboxWidth = `${((bbox.xmax || 0.92) - (bbox.xmin || 0.08)) * 100}%`;

  const confPercent = currentItem?.model_confidence 
    ? Math.round(currentItem.model_confidence * 1000) / 10 
    : 74.5;

  const receiptId = currentItem?.receipt_id || currentItem?.line_item?.receipt_id;
  const queueId = currentItem?.id || currentItem?.queue_id;

  // Images
  const cropUrl = queueId ? api.getReviewCropUrl(queueId) : null;
  const receiptImageUrl = receiptId ? api.getReceiptImageUrl(receiptId) : null;

  return (
    <div className="flex flex-col bg-white border border-[#CBD5E1] rounded overflow-hidden shadow-none h-full">
      {/* Workspace Sub-Header */}
      <div className="bg-[#0F172A] border-b border-[#334155] px-4 py-2.5 flex items-center justify-between text-white select-none">
        <div className="flex items-center gap-2">
          <Scan className="w-4 h-4 text-emerald-400" />
          <span className="font-mono font-bold text-xs tracking-wider uppercase">
            WORKSPACE A: HUMAN-IN-THE-LOOP REVIEW DESK
          </span>
          <span className="font-mono text-[11px] bg-slate-800 text-slate-300 border border-slate-700 px-1.5 py-0.2 rounded">
            50% Split
          </span>
        </div>

        {/* Item Counter & Navigation */}
        {queueItems.length > 0 && (
          <div className="flex items-center gap-2 font-mono text-xs">
            <span className="text-slate-400">
              Queue: <strong className="text-amber-400">{activeQueueIndex + 1}</strong> of <strong className="text-white">{queueItems.length}</strong>
            </span>
            <div className="flex items-center border border-slate-700 rounded bg-slate-900">
              <button
                onClick={() => setActiveQueueIndex(Math.max(0, activeQueueIndex - 1))}
                disabled={activeQueueIndex === 0}
                className="p-1 hover:bg-slate-800 disabled:opacity-30 text-slate-300"
                title="Previous item"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => setActiveQueueIndex(Math.min(queueItems.length - 1, activeQueueIndex + 1))}
                disabled={activeQueueIndex === queueItems.length - 1}
                className="p-1 hover:bg-slate-800 disabled:opacity-30 text-slate-300"
                title="Next item"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Main Review Desk Content */}
      {queueItems.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center p-8 text-center bg-slate-50">
          <div className="w-12 h-12 bg-emerald-100 border border-emerald-300 rounded-full flex items-center justify-center text-emerald-700 mb-3">
            <CheckCircle2 className="w-6 h-6" />
          </div>
          <h3 className="font-mono font-bold text-sm text-slate-900 uppercase tracking-wide">
            Human Review Queue Cleared
          </h3>
          <p className="text-xs text-slate-500 max-w-sm mt-1 font-sans">
            All ambiguous receipt scans (&lt; 85% confidence) have been reconciled and verified.
          </p>
          <div className="mt-4">
            <span className="text-xs font-mono text-slate-600 bg-white border border-[#CBD5E1] px-3 py-1 rounded">
              Status: 100% Ingested Line Items Verified
            </span>
          </div>
        </div>
      ) : (
        <div className="flex-1 grid grid-cols-1 lg:grid-cols-12 overflow-hidden min-h-[500px]">
          {/* Left Canvas: Scaled Receipt Viewer with Interactive Pan & Zoom */}
          <div className="lg:col-span-7 border-b lg:border-b-0 lg:border-r border-[#CBD5E1] bg-slate-900 flex flex-col relative select-none">
            {/* Canvas Toolbar */}
            <div className="bg-slate-950/90 border-b border-slate-800 px-3 py-1.5 flex items-center justify-between text-xs font-mono text-slate-300 z-10">
              <div className="flex items-center gap-2">
                <span className="text-slate-400">Mode:</span>
                <button
                  onClick={() => setViewMode('full')}
                  className={`px-2 py-0.5 rounded text-[11px] font-semibold border ${
                    viewMode === 'full' 
                      ? 'bg-emerald-700 text-white border-emerald-500' 
                      : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-white'
                  }`}
                >
                  Full Receipt
                </button>
                <button
                  onClick={() => setViewMode('crop')}
                  className={`px-2 py-0.5 rounded text-[11px] font-semibold border ${
                    viewMode === 'crop' 
                      ? 'bg-emerald-700 text-white border-emerald-500' 
                      : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-white'
                  }`}
                >
                  Cropped Snippet
                </button>
              </div>

              {/* Zoom Controls */}
              <div className="flex items-center gap-1.5">
                <button
                  onClick={handleZoomOut}
                  title="Zoom Out (-)"
                  className="p-1 bg-slate-900 hover:bg-slate-800 text-slate-300 border border-slate-800 rounded"
                >
                  <ZoomOut className="w-3.5 h-3.5" />
                </button>
                <span className="w-12 text-center text-[11px] text-slate-300 font-mono">
                  {Math.round(zoom * 100)}%
                </span>
                <button
                  onClick={handleZoomIn}
                  title="Zoom In (+)"
                  className="p-1 bg-slate-900 hover:bg-slate-800 text-slate-300 border border-slate-800 rounded"
                >
                  <ZoomIn className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={handleZoomReset}
                  title="Reset (100%)"
                  className="p-1 bg-slate-900 hover:bg-slate-800 text-slate-300 border border-slate-800 rounded"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={handleZoomFit}
                  title="Fit to Candidate"
                  className="p-1 bg-slate-900 hover:bg-slate-800 text-slate-300 border border-slate-800 rounded"
                >
                  <Maximize2 className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

            {/* Interactive Viewport */}
            <div 
              ref={canvasRef}
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
              className={`flex-1 relative overflow-hidden flex items-center justify-center p-4 ${
                isDragging ? 'cursor-grabbing' : 'cursor-grab'
              }`}
              style={{ backgroundColor: '#0B0F19' }}
            >
              {viewMode === 'crop' && cropUrl ? (
                /* Cropped Snippet View (/api/v1/review-queue/{id}/crop) */
                <div 
                  className="transition-transform duration-75 relative border border-slate-700 bg-white"
                  style={{
                    transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
                    transformOrigin: 'center center',
                  }}
                >
                  <img
                    src={cropUrl}
                    alt="Cropped Item Snippet"
                    className="max-h-[380px] max-w-[420px] object-contain shadow-lg"
                    onError={(e) => {
                      e.target.onerror = null;
                      setViewMode('full'); // Fallback to full image if crop not generated
                    }}
                  />
                  <div className="absolute top-2 right-2 bg-red-600 text-white font-mono text-[10px] font-bold px-1.5 py-0.5 rounded">
                    LOW CONFIDENCE &lt; 85%
                  </div>
                </div>
              ) : (
                /* Scaled Full Receipt Viewer with Glowing 2px Bounding-Box Highlight */
                <div 
                  className="transition-transform duration-75 relative border border-slate-700 bg-white shadow-2xl"
                  style={{
                    transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
                    transformOrigin: 'center center',
                    width: '340px',
                    minHeight: '480px',
                  }}
                >
                  {receiptImageUrl ? (
                    <img
                      src={receiptImageUrl}
                      alt="Full Preprocessed Receipt"
                      className="w-full h-auto block select-none"
                      onError={(e) => {
                        e.target.style.display = 'none';
                        const parent = e.target.parentElement;
                        if (parent) {
                          parent.classList.add('p-6', 'text-slate-800', 'font-mono');
                        }
                      }}
                    />
                  ) : null}

                  {/* Fallback layout simulator if raw image file is pending */}
                  <div className="p-4 font-mono text-[11px] text-slate-800 pointer-events-none select-none">
                    <div className="text-center font-bold border-b border-slate-300 pb-2 mb-3">
                      <div>{currentItem?.merchant_name || 'RETAIL POS STORE'}</div>
                      <div className="text-[9px] text-slate-500 mt-0.5">SNTN: 2939022-8 • CASH SALE</div>
                    </div>
                    <div className="space-y-2 py-2">
                      <div className="flex justify-between text-slate-600">
                        <span>1. FRESH MILK 1L</span>
                        <span>PKR 280.00</span>
                      </div>
                      <div className="flex justify-between font-bold bg-amber-50 p-1 border border-amber-200 text-slate-900">
                        <span>{currentItem?.candidate_name || currentItem?.candidate_text}</span>
                        <span>PKR {formData.confirmed_total_price}</span>
                      </div>
                      <div className="flex justify-between text-slate-600">
                        <span>3. WHEAT FLOUR 10KG</span>
                        <span>PKR 1,450.00</span>
                      </div>
                    </div>
                  </div>

                  {/* Glowing 2px bounding-box snippet highlight */}
                  <div 
                    className="absolute glow-bounding-box pointer-events-none transition-all duration-150"
                    style={{
                      top: bboxTop,
                      left: bboxLeft,
                      width: bboxWidth,
                      height: bboxHeight,
                    }}
                  >
                    <span className="absolute -top-5 left-0 bg-red-600 text-white font-mono text-[9px] font-bold px-1 py-0.2 rounded shadow">
                      {confPercent}% CONF
                    </span>
                  </div>
                </div>
              )}

              {/* Viewport Hint */}
              <div className="absolute bottom-2 left-2 text-[10px] font-mono text-slate-400 bg-slate-950/80 px-2 py-1 rounded border border-slate-800 pointer-events-none">
                Pan: Drag with mouse • Zoom: Mouse Wheel / Top Controls
              </div>
            </div>
          </div>

          {/* Right Triage Form: Item Candidate Name, Qty, Price & Tactile Controls */}
          <div className="lg:col-span-5 flex flex-col justify-between bg-white p-5 overflow-y-auto">
            <div className="space-y-4">
              {/* Status feedback notification banner */}
              {statusMessage && (
                <div className={`p-2.5 rounded font-mono text-xs flex items-center gap-2 border ${
                  statusMessage.type === 'ERROR'
                    ? 'bg-red-50 text-red-700 border-red-300'
                    : 'bg-emerald-50 text-emerald-800 border-emerald-300'
                }`}>
                  <CheckCircle2 className="w-4 h-4 shrink-0" />
                  <span>{statusMessage.msg}</span>
                </div>
              )}

              {/* Merchant Context Header */}
              <div className="bg-slate-50 border border-[#CBD5E1] p-3 rounded">
                <div className="text-[10px] font-mono font-bold uppercase tracking-wider text-slate-500">
                  MERCHANT &amp; OCR SOURCE
                </div>
                <div className="font-mono font-bold text-sm text-slate-900 mt-0.5">
                  {currentItem?.merchant_name || 'Chaudhry Sabzi & Fruit Store'}
                </div>
                <div className="text-[11px] font-mono text-slate-500 mt-1 flex items-center gap-2">
                  <span>Receipt ID:</span>
                  <span className="text-slate-700">{receiptId ? receiptId.slice(0, 13) + '...' : '41fd8d2a-...'}</span>
                </div>
              </div>

              {/* Raw OCR Text snippet badge */}
              <div className="bg-amber-50/60 border border-amber-200 p-3 rounded">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[10px] font-mono font-bold uppercase tracking-wider text-amber-800">
                    RAW OCR TEXT CANDIDATE
                  </span>
                  <span className="font-mono text-[11px] font-bold text-amber-700 bg-amber-100 border border-amber-300 px-1.5 py-0.2 rounded">
                    Score: {confPercent}%
                  </span>
                </div>
                <div className="font-mono text-xs text-slate-800 bg-white border border-amber-300 p-2 rounded">
                  {currentItem?.raw_text || currentItem?.candidate_text || '129728 WITHA PER KG 0.640'}
                </div>
                <div className="text-[10px] text-amber-700 font-sans mt-1">
                  Confidence score below 85% threshold. Verify spelling and line numbers.
                </div>
              </div>

              {/* Candidate Form Fields */}
              <div className="space-y-3 pt-1">
                {/* 1. Candidate Item Name */}
                <div>
                  <label className="block text-xs font-mono font-semibold text-slate-700 uppercase mb-1">
                    Candidate Item Name:
                  </label>
                  <input
                    ref={nameInputRef}
                    type="text"
                    value={formData.confirmed_name}
                    onChange={(e) => setFormData({ ...formData, confirmed_name: e.target.value })}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        handleAccept();
                      }
                    }}
                    placeholder="e.g. Sweet Melon"
                    className="w-full font-mono text-sm bg-white border border-[#CBD5E1] focus:border-slate-800 focus:ring-1 focus:ring-slate-800 px-3 py-2 rounded outline-none"
                  />
                </div>

                {/* 2. Quantity & Unit */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-mono font-semibold text-slate-700 uppercase mb-1">
                      Quantity:
                    </label>
                    <input
                      type="number"
                      step="0.01"
                      value={formData.confirmed_quantity}
                      onChange={handleQtyChange}
                      className="w-full font-mono text-sm bg-white border border-[#CBD5E1] focus:border-slate-800 px-3 py-2 rounded outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-mono font-semibold text-slate-700 uppercase mb-1">
                      Unit:
                    </label>
                    <input
                      type="text"
                      value={formData.confirmed_unit}
                      onChange={(e) => setFormData({ ...formData, confirmed_unit: e.target.value })}
                      placeholder="kg, pcs, ltr"
                      className="w-full font-mono text-sm bg-white border border-[#CBD5E1] focus:border-slate-800 px-3 py-2 rounded outline-none"
                    />
                  </div>
                </div>

                {/* 3. Unit Price & Total Price */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-mono font-semibold text-slate-700 uppercase mb-1">
                      Unit Price (PKR):
                    </label>
                    <input
                      type="number"
                      step="0.5"
                      value={formData.confirmed_unit_price}
                      onChange={handlePriceChange}
                      className="w-full font-mono text-sm bg-white border border-[#CBD5E1] focus:border-slate-800 px-3 py-2 rounded outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-mono font-semibold text-slate-700 uppercase mb-1">
                      Total (PKR):
                    </label>
                    <input
                      type="number"
                      step="0.5"
                      value={formData.confirmed_total_price}
                      onChange={(e) => setFormData({ ...formData, confirmed_total_price: parseFloat(e.target.value) || 0 })}
                      className="w-full font-mono text-sm font-bold bg-slate-50 border border-[#CBD5E1] focus:border-slate-800 px-3 py-2 rounded outline-none"
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Tactile Controls: [Confirm & Accept (Enter)] | [Save Edits (Ctrl+S)] */}
            <div className="pt-6 border-t border-[#CBD5E1] space-y-2.5">
              <div className="grid grid-cols-2 gap-2.5">
                {/* 1-Click Accept Button */}
                <button
                  type="button"
                  onClick={handleAccept}
                  disabled={resolving}
                  className="flex items-center justify-center gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-mono text-xs font-bold py-2.5 px-3 rounded border border-emerald-700 transition-colors cursor-pointer"
                  title="1-Click Approve active item and advance (Hotkey: Enter)"
                >
                  <Check className="w-4 h-4" />
                  <span>Confirm &amp; Accept</span>
                  <kbd className="ml-1 text-[10px] bg-emerald-700 text-emerald-100 border-emerald-800">Enter</kbd>
                </button>

                {/* Save Edits Button */}
                <button
                  type="button"
                  onClick={handleSaveEdits}
                  disabled={resolving}
                  className="flex items-center justify-center gap-1.5 bg-slate-800 hover:bg-slate-700 text-white font-mono text-xs font-bold py-2.5 px-3 rounded border border-slate-900 transition-colors cursor-pointer"
                  title="Save inline edits on candidate name, qty, or price (Hotkey: Ctrl+S)"
                >
                  <Save className="w-4 h-4" />
                  <span>Save Edits</span>
                  <kbd className="ml-1 text-[10px] bg-slate-900 text-slate-200 border-slate-800">Ctrl+S</kbd>
                </button>
              </div>

              {/* Auto-advance indication */}
              <div className="flex items-center justify-between text-[11px] font-mono text-slate-500 px-1">
                <span>Action auto-advances queue to next item</span>
                <span>Tab / Shift+Tab navigates fields</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
