import React, { useState, useEffect, useRef } from 'react';
import {
  Scan,
  ZoomIn,
  ZoomOut,
  RotateCcw,
  Maximize2,
  Check,
  Save,
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
  AlertTriangle,
  WifiOff,
} from 'lucide-react';
import { ReviewQueueItem, ReviewQueueResolveRequest } from '../../types';
import { api } from '../../api/client';
import { computeBoundingBoxStyle, getConfidenceTier } from '../../lib/adapter';
import { formatPKR } from '../../lib/formatters';

export interface ReviewDeskProps {
  queueItems: ReviewQueueItem[];
  activeIndex: number;
  onSelectIndex: (index: number) => void;
  onResolveItem: (queueId: string, payload: ReviewQueueResolveRequest) => Promise<void>;
  isResolving: boolean;
  isLoading?: boolean;
  isMockMode?: boolean;
  onReloadMockQueue?: () => void;
  onEnterDevMockMode?: () => void;
}

export const ReviewDesk: React.FC<ReviewDeskProps> = ({
  queueItems,
  activeIndex,
  onSelectIndex,
  onResolveItem,
  isResolving,
  isLoading = false,
  isMockMode = false,
  onReloadMockQueue,
  onEnterDevMockMode,
}) => {
  const currentItem = queueItems[activeIndex] || null;

  // Pan & Zoom state (100% to 400%)
  const [zoom, setZoom] = useState<number>(1.5);
  const [pan, setPan] = useState<{ x: number; y: number }>({ x: 0, y: -20 });
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragStart, setDragStart] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [viewMode, setViewMode] = useState<'full' | 'crop'>('full');
  const [imageError, setImageError] = useState<boolean>(false);

  // Form Fields
  const [confirmedName, setConfirmedName] = useState<string>('');
  const [confirmedQty, setConfirmedQty] = useState<number>(1);
  const [confirmedUnit, setConfirmedUnit] = useState<string>('pcs');
  const [confirmedUnitPrice, setConfirmedUnitPrice] = useState<number>(0);
  const [confirmedTotalPrice, setConfirmedTotalPrice] = useState<number>(0);

  const nameInputRef = useRef<HTMLInputElement>(null);
  const canvasContainerRef = useRef<HTMLDivElement>(null);

  // Sync state whenever active review item changes
  useEffect(() => {
    if (currentItem) {
      const li = currentItem.line_item;
      const initialName =
        currentItem.candidate_name || currentItem.candidate_text || li?.item_name || '';
      const initialQty = li?.quantity ?? 1;
      const initialUnit = li?.unit ?? 'pcs';
      const initialUnitPrice = li?.unit_price ?? 0;
      const initialTotal = li?.total_price ?? initialQty * initialUnitPrice;

      setConfirmedName(initialName);
      setConfirmedQty(initialQty);
      setConfirmedUnit(initialUnit);
      setConfirmedUnitPrice(initialUnitPrice);
      setConfirmedTotalPrice(Math.round(initialTotal * 100) / 100);
      setImageError(Boolean(isMockMode && !currentItem.receipt_image_url));

      // Auto-focus candidate product name for rapid operator triage
      setTimeout(() => {
        if (nameInputRef.current) {
          nameInputRef.current.focus();
          nameInputRef.current.select();
        }
      }, 50);
    }
  }, [currentItem, activeIndex, isMockMode]);

  // Handle Qty & Price recalculation
  const handleQtyChange = (val: number) => {
    setConfirmedQty(val);
    setConfirmedTotalPrice(Math.round(val * confirmedUnitPrice * 100) / 100);
  };

  const handleUnitPriceChange = (val: number) => {
    setConfirmedUnitPrice(val);
    setConfirmedTotalPrice(Math.round(confirmedQty * val * 100) / 100);
  };

  // Zoom handlers (100% to 400%)
  const handleZoomIn = () => setZoom((z) => Math.min(4.0, Math.round((z + 0.25) * 100) / 100));
  const handleZoomOut = () => setZoom((z) => Math.max(1.0, Math.round((z - 0.25) * 100) / 100));
  const handleZoom100 = () => {
    setZoom(1.0);
    setPan({ x: 0, y: 0 });
  };
  const handleZoomFit = () => {
    setZoom(1.5);
    setPan({ x: 0, y: -20 });
  };

  // Mouse wheel zoom
  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    if (e.deltaY < 0) {
      handleZoomIn();
    } else {
      handleZoomOut();
    }
  };

  // Drag to pan handlers
  const handleMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return;
    setIsDragging(true);
    setDragStart({ x: e.clientX - pan.x, y: e.clientY - pan.y });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    setPan({
      x: e.clientX - dragStart.x,
      y: e.clientY - dragStart.y,
    });
  };

  const handleMouseUp = () => setIsDragging(false);

  // Double click reset
  const handleDoubleClick = () => {
    handleZoom100();
  };

  // Action: 1-Click Accept (Enter)
  const handleAccept = async () => {
    if (!currentItem || isResolving) return;
    const queueId = currentItem.queue_id || currentItem.id;
    await onResolveItem(queueId, {
      confirmed_name: confirmedName.trim() || currentItem.candidate_name || 'Accepted Item',
      action: 'ACCEPTED',
    });
  };

  // Action: Save Edits (Ctrl+S)
  const handleSaveEdits = async () => {
    if (!currentItem || isResolving) return;
    const queueId = currentItem.queue_id || currentItem.id;
    await onResolveItem(queueId, {
      confirmed_name: confirmedName.trim() || currentItem.candidate_name || 'Corrected Item',
      confirmed_quantity: confirmedQty,
      confirmed_unit: confirmedUnit,
      confirmed_unit_price: confirmedUnitPrice,
      confirmed_total_price: confirmedTotalPrice,
      action: 'EDITED',
    });
  };

  // Loading skeleton state
  if (isLoading) {
    return (
      <div className="flex flex-col bg-white border border-[#CBD5E1] rounded-2xl overflow-hidden h-full select-none">
        <div className="bg-white border-b border-[#CBD5E1] px-5 py-3 flex items-center justify-between">
          <div className="w-48 h-4 bg-slate-200 rounded"></div>
          <div className="w-24 h-4 bg-slate-200 rounded"></div>
        </div>
        <div className="flex-1 grid grid-cols-1 md:grid-cols-2 divide-y md:divide-y-0 md:divide-x divide-[#CBD5E1]">
          <div className="bg-slate-900 p-6 flex items-center justify-center">
            <div className="w-48 h-64 bg-slate-800 rounded border border-slate-700"></div>
          </div>
          <div className="bg-white p-6 space-y-4">
            <div className="w-36 h-4 bg-slate-200 rounded"></div>
            <div className="w-full h-16 bg-slate-100 rounded"></div>
            <div className="w-full h-10 bg-slate-200 rounded"></div>
            <div className="grid grid-cols-3 gap-2">
              <div className="h-10 bg-slate-100 rounded"></div>
              <div className="h-10 bg-slate-100 rounded"></div>
              <div className="h-10 bg-slate-100 rounded"></div>
            </div>
            <div className="w-full h-12 bg-slate-200 rounded"></div>
          </div>
        </div>
      </div>
    );
  }

  // Derived attributes
  const queueId = currentItem?.queue_id || currentItem?.id;
  const receiptId = currentItem?.receipt_id || currentItem?.line_item?.receipt_id;
  const rawText = currentItem?.raw_text || currentItem?.line_item?.raw_text || '';
  const merchantName = currentItem?.merchant_name || 'Chaudhry Sabzi & Fruit Store';
  const confidenceTier = getConfidenceTier(currentItem?.model_confidence);

  // Bounding box snippet positioning
  const bboxStyle = computeBoundingBoxStyle(currentItem?.line_item?.bbox, activeIndex, queueItems.length);

  const receiptImageUrl =
    currentItem?.receipt_image_url !== undefined
      ? currentItem.receipt_image_url
      : (isMockMode ? '' : (receiptId ? api.getReceiptImageUrl(receiptId) : ''));
  const cropImageUrl =
    currentItem?.crop_image_url !== undefined
      ? currentItem.crop_image_url
      : (isMockMode ? '' : (queueId ? api.getReviewCropUrl(queueId) : ''));

  return (
    <div className="flex flex-col bg-white border border-[#CBD5E1] rounded-2xl overflow-hidden h-full select-none">
      {/* ── Sub-Header: Pinterest-styled clean white surface with crisp border ── */}
      <div className="bg-white border-b border-[#CBD5E1] px-5 py-3 flex items-center justify-between text-slate-900">
        <div className="flex items-center gap-2.5">
          <div className="w-6 h-6 bg-black text-white rounded-lg flex items-center justify-center shrink-0">
            <Scan className="w-3.5 h-3.5 text-white" />
          </div>
          <span className="font-mono font-bold text-xs tracking-wider uppercase text-slate-900">
            WORKSPACE A: HUMAN-IN-THE-LOOP REVIEW DESK
          </span>
          <span className="font-mono text-[10px] font-semibold bg-[#F1F5F9] text-slate-700 border border-[#CBD5E1] px-1.5 py-0.5 rounded">
            50% Split
          </span>
          {isMockMode && (
            <span className="flex items-center gap-1 font-mono text-[10px] font-bold bg-amber-50 text-amber-900 border border-amber-300 px-2 py-0.5 rounded">
              <WifiOff className="w-3 h-3 text-amber-700" />
              OFFLINE DEMO QUEUE
            </span>
          )}
        </div>

        {/* Queue Position (e.g. 1 of 7) and tactile controls */}
        {queueItems.length > 0 ? (
          <div className="flex items-center gap-2.5 font-mono text-xs">
            {isMockMode && onReloadMockQueue && (
              <button
                type="button"
                onClick={onReloadMockQueue}
                title="Reload initial mock review queue"
                className="flex items-center gap-1 text-[11px] font-mono font-semibold text-slate-700 hover:text-black hover:bg-slate-100 border border-[#CBD5E1] px-2 py-1 rounded-lg transition-colors cursor-pointer"
              >
                <RotateCcw className="w-3 h-3 text-slate-500" />
                <span>Reload Queue</span>
              </button>
            )}
            <span className="text-slate-500">
              Queue Position:{' '}
              <strong className="text-slate-900 font-bold">{activeIndex + 1}</strong> of{' '}
              <strong className="text-slate-900 font-bold">{queueItems.length}</strong>
            </span>
            <div className="flex items-center border border-[#CBD5E1] rounded-lg bg-white overflow-hidden shadow-none">
              <button
                type="button"
                onClick={() => onSelectIndex(Math.max(0, activeIndex - 1))}
                disabled={activeIndex === 0}
                className="p-1.5 hover:bg-slate-100 disabled:opacity-30 text-slate-700 transition-colors cursor-pointer border-r border-[#CBD5E1]"
                title="Previous flagged item ([)"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              <button
                type="button"
                onClick={() => onSelectIndex(Math.min(queueItems.length - 1, activeIndex + 1))}
                disabled={activeIndex === queueItems.length - 1}
                className="p-1.5 hover:bg-slate-100 disabled:opacity-30 text-slate-700 transition-colors cursor-pointer"
                title="Next flagged item (])"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        ) : (
          isMockMode && onReloadMockQueue && (
            <button
              type="button"
              onClick={onReloadMockQueue}
              className="flex items-center gap-1 text-[11px] font-mono font-semibold text-slate-700 hover:text-black hover:bg-slate-100 border border-[#CBD5E1] px-2.5 py-1 rounded-lg transition-colors cursor-pointer"
            >
              <RotateCcw className="w-3 h-3 text-slate-500" />
              <span>Reload Mock Queue</span>
            </button>
          )
        )}
      </div>

      {/* ── Desk Body ────────────────────────────────────────────────────────── */}
      {queueItems.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center p-8 text-center bg-[#F8FAFC]">
          <div className="w-12 h-12 bg-emerald-50 border border-emerald-300 rounded-2xl flex items-center justify-center text-emerald-700 mb-3">
            <CheckCircle2 className="w-6 h-6" />
          </div>
          <h3 className="font-mono font-bold text-sm text-slate-900 uppercase tracking-wide">
            Human Review Queue Cleared
          </h3>
          <p className="text-xs text-slate-500 max-w-sm mt-1 font-sans">
            All ambiguous receipt scans (&lt; 85% confidence) have been reconciled and verified.
          </p>
          <div className="mt-4 flex flex-col sm:flex-row items-center gap-2.5">
            <span className="text-xs font-mono font-semibold text-slate-700 bg-white border border-[#CBD5E1] px-3 py-1.5 rounded-xl">
              Status: 100% Ingested Line Items Verified
            </span>
            {(isMockMode || onReloadMockQueue || onEnterDevMockMode) && (
              <button
                type="button"
                onClick={onReloadMockQueue || onEnterDevMockMode}
                className="inline-flex items-center gap-1.5 bg-black hover:bg-slate-800 text-white font-mono text-xs font-bold px-3 py-1.5 rounded-xl border border-black transition-colors cursor-pointer"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                <span>
                  {isMockMode ? 'Reload Mock Review Queue' : 'Load Mock Review Items'}
                </span>
              </button>
            )}
          </div>
        </div>
      ) : (
        <div className="flex-1 grid grid-cols-1 md:grid-cols-2 divide-y md:divide-y-0 md:divide-x divide-[#CBD5E1] min-h-[460px]">
          {/* ── LEFT CANVAS: Receipt Image Viewer with Pan & Zoom ─────────────── */}
          <div className="flex flex-col bg-slate-900 h-full relative overflow-hidden">
            {/* View Mode & Zoom Toolbar */}
            <div className="bg-[#0F172A] border-b border-slate-800 px-3.5 py-2 flex items-center justify-between text-white text-xs font-mono z-10">
              <div className="flex items-center gap-1.5 bg-slate-900 border border-slate-800 p-0.5 rounded-lg">
                <button
                  type="button"
                  onClick={() => setViewMode('full')}
                  className={`px-2 py-0.5 rounded-md text-[11px] font-semibold transition-colors cursor-pointer ${
                    viewMode === 'full'
                      ? 'bg-black text-white border border-slate-700'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  Full Receipt
                </button>
                <button
                  type="button"
                  onClick={() => setViewMode('crop')}
                  className={`px-2 py-0.5 rounded-md text-[11px] font-semibold transition-colors cursor-pointer ${
                    viewMode === 'crop'
                      ? 'bg-black text-white border border-slate-700'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  Item Snippet
                </button>
              </div>

              {/* Pan & Zoom Controls */}
              <div className="flex items-center gap-1">
                <span className="text-[11px] text-slate-400 w-12 text-right mr-1 font-semibold">
                  {Math.round(zoom * 100)}%
                </span>
                <button
                  type="button"
                  onClick={handleZoomIn}
                  className="w-7 h-7 bg-slate-900 hover:bg-slate-800 text-slate-200 rounded-lg border border-slate-800 flex items-center justify-center transition-colors cursor-pointer"
                  title="Zoom In (+25%)"
                >
                  <ZoomIn className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={handleZoomOut}
                  className="w-7 h-7 bg-slate-900 hover:bg-slate-800 text-slate-200 rounded-lg border border-slate-800 flex items-center justify-center transition-colors cursor-pointer"
                  title="Zoom Out (-25%)"
                >
                  <ZoomOut className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={handleZoomFit}
                  className="w-7 h-7 bg-slate-900 hover:bg-slate-800 text-slate-200 rounded-lg border border-slate-800 flex items-center justify-center transition-colors cursor-pointer"
                  title="Fit Receipt"
                >
                  <Maximize2 className="w-3.5 h-3.5" />
                </button>
                <button
                  type="button"
                  onClick={handleZoom100}
                  className="w-7 h-7 bg-slate-900 hover:bg-slate-800 text-slate-200 rounded-lg border border-slate-800 flex items-center justify-center transition-colors cursor-pointer"
                  title="Reset 100% (Double click)"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

            {/* Canvas Area */}
            <div
              ref={canvasContainerRef}
              onWheel={handleWheel}
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onDoubleClick={handleDoubleClick}
              className={`flex-1 relative overflow-hidden flex items-center justify-center p-4 select-none ${
                isDragging ? 'cursor-grabbing' : 'cursor-grab'
              }`}
            >
              {imageError ? (
                <div className="text-center font-mono text-xs text-slate-400 space-y-2 bg-slate-950/80 border border-slate-800 p-6 rounded-2xl max-w-xs">
                  <AlertTriangle className="w-8 h-8 text-amber-500 mx-auto" />
                  <div className="font-semibold text-slate-200">Receipt scan unavailable</div>
                  <div className="text-[11px] text-slate-400 leading-relaxed">
                    Image file not found on disk. Triage details are preserved from database record.
                  </div>
                </div>
              ) : viewMode === 'full' ? (
                /* Full Receipt Canvas with 2px solid Bounding Box Highlight */
                <div
                  style={{
                    transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
                    transformOrigin: 'center center',
                    transition: isDragging ? 'none' : 'transform 0.1s ease-out',
                  }}
                  className="relative inline-block max-w-full"
                >
                  <img
                    src={receiptImageUrl}
                    alt="Receipt Scan"
                    onError={() => setImageError(true)}
                    style={{ imageRendering: 'crisp-edges' }}
                    className="max-h-[520px] object-contain block border border-slate-800 bg-white"
                  />

                  {/* 2px Solid Bounding Box Highlight (No glow, solid crisp outline) */}
                  <div
                    style={{
                      top: bboxStyle.top,
                      left: bboxStyle.left,
                      width: bboxStyle.width,
                      height: bboxStyle.height,
                    }}
                    className="absolute border-2 border-red-600 bg-red-600/10 pointer-events-none"
                    title="Active OCR candidate snippet"
                  >
                    <span className="absolute -top-4 left-0 bg-red-600 text-white font-mono text-[9px] font-bold px-1.5 py-0.5 uppercase tracking-wider">
                      ACTIVE SNIPPET
                    </span>
                  </div>
                </div>
              ) : (
                /* Cropped Snippet View */
                <div
                  style={{
                    transform: `translate(${pan.x}px, ${pan.y}px) scale(${zoom})`,
                    transformOrigin: 'center center',
                    transition: isDragging ? 'none' : 'transform 0.1s ease-out',
                  }}
                  className="relative inline-block"
                >
                  <img
                    src={cropImageUrl}
                    alt="Cropped Item Snippet"
                    onError={() => setImageError(true)}
                    className="max-h-[300px] object-contain block border-2 border-red-600 bg-white"
                  />
                  <div className="text-center mt-1 text-[10px] font-mono text-slate-400">
                    Cropped JPEG Snippet from /review-queue/{queueId}/crop
                  </div>
                </div>
              )}
            </div>

            {/* Bottom canvas navigation hint */}
            <div className="bg-[#0F172A] border-t border-slate-800 px-3.5 py-1.5 text-[11px] font-mono text-slate-400 flex items-center justify-between">
              <span>Drag to pan • Mouse wheel to zoom (100% - 400%)</span>
              <span>Double-click to reset (100%)</span>
            </div>
          </div>

          {/* ── RIGHT TRIAGE FORM: Operator Verification ─────────────────────── */}
          <div className="flex flex-col bg-white p-6 justify-between space-y-4">
            <div className="space-y-4">
              {/* Top: Merchant & Confidence pill */}
              <div className="flex items-start justify-between gap-3 border-b border-[#CBD5E1] pb-3">
                <div>
                  <div className="text-[10px] font-mono uppercase text-slate-400 font-semibold">
                    Merchant Store
                  </div>
                  <h3
                    dir="auto"
                    className="font-mono font-bold text-sm text-slate-900 mt-0.5"
                  >
                    {merchantName}
                  </h3>
                </div>

                {/* Model Confidence Pill */}
                <div className="text-right">
                  <div className="text-[10px] font-mono uppercase text-slate-400 font-semibold">
                    Model Confidence
                  </div>
                  <span
                    className={`inline-flex items-center gap-1 font-mono text-xs font-bold px-2 py-0.5 rounded border mt-0.5 ${confidenceTier.badgeClasses}`}
                  >
                    <span>{confidenceTier.percent}%</span>
                    <span>•</span>
                    <span>{confidenceTier.label}</span>
                  </span>
                </div>
              </div>

              {/* Raw OCR Reading (Monospace, dir="auto") */}
              <div>
                <label className="block text-[11px] font-mono font-bold uppercase text-slate-600 mb-1">
                  Raw OCR Snippet (Machine Output)
                </label>
                <div
                  dir="auto"
                  className="bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-xl font-mono text-xs text-slate-800 break-all select-text"
                >
                  {rawText || '—'}
                </div>
              </div>

              {/* Candidate Item Name (Editable, dir="auto", auto-focused) */}
              <div>
                <label className="block text-[11px] font-mono font-bold uppercase text-slate-800 mb-1">
                  Candidate Product Name
                </label>
                <input
                  ref={nameInputRef}
                  type="text"
                  dir="auto"
                  data-triage-field="true"
                  value={confirmedName}
                  onChange={(e) => setConfirmedName(e.target.value)}
                  className="w-full bg-white font-mono text-xs text-slate-900 border border-[#CBD5E1] focus:border-black focus:ring-1 focus:ring-black p-2.5 rounded-xl outline-none transition-colors"
                  placeholder="Normalized Product Name"
                />
              </div>

              {/* Numerical Triage Grid: Quantity, Unit, Unit Price, Total */}
              <div className="grid grid-cols-3 gap-2.5">
                <div>
                  <label className="block text-[10px] font-mono font-semibold uppercase text-slate-600 mb-1">
                    Quantity
                  </label>
                  <input
                    type="number"
                    step="any"
                    min="0"
                    data-triage-field="true"
                    value={confirmedQty}
                    onChange={(e) => handleQtyChange(parseFloat(e.target.value) || 0)}
                    className="w-full bg-white font-mono text-xs text-slate-900 border border-[#CBD5E1] focus:border-black focus:ring-1 focus:ring-black p-2 rounded-xl outline-none transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-[10px] font-mono font-semibold uppercase text-slate-600 mb-1">
                    Unit
                  </label>
                  <input
                    type="text"
                    data-triage-field="true"
                    value={confirmedUnit}
                    onChange={(e) => setConfirmedUnit(e.target.value)}
                    className="w-full bg-white font-mono text-xs text-slate-900 border border-[#CBD5E1] focus:border-black focus:ring-1 focus:ring-black p-2 rounded-xl outline-none transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-[10px] font-mono font-semibold uppercase text-slate-600 mb-1">
                    Unit Price (PKR)
                  </label>
                  <input
                    type="number"
                    step="any"
                    min="0"
                    data-triage-field="true"
                    value={confirmedUnitPrice}
                    onChange={(e) => handleUnitPriceChange(parseFloat(e.target.value) || 0)}
                    className="w-full bg-white font-mono text-xs text-slate-900 border border-[#CBD5E1] focus:border-black focus:ring-1 focus:ring-black p-2 rounded-xl outline-none transition-colors"
                  />
                </div>
              </div>

              {/* Computed Line Total */}
              <div className="bg-[#F8FAFC] border border-[#CBD5E1] p-3 rounded-xl flex items-center justify-between font-mono">
                <span className="text-xs text-slate-600 font-semibold uppercase">Reconciled Line Total:</span>
                <span className="text-sm font-bold text-slate-900">
                  {formatPKR(confirmedTotalPrice)}
                </span>
              </div>
            </div>

            {/* ── Tactile Verification Controls ────────────────────────────── */}
            <div className="pt-2 border-t border-[#CBD5E1] space-y-2">
              <div className="grid grid-cols-2 gap-2.5">
                {/* 1-Click Accept (Enter) */}
                <button
                  type="button"
                  onClick={handleAccept}
                  disabled={isResolving}
                  className="flex items-center justify-center gap-1.5 bg-black hover:bg-slate-800 text-white font-mono text-xs font-bold py-3 px-4 rounded-xl border border-black transition-colors disabled:opacity-50 cursor-pointer"
                >
                  <Check className="w-4 h-4" />
                  <span>Confirm &amp; Accept</span>
                  <kbd className="ml-1 bg-slate-800 text-slate-200 border border-slate-700 px-1.5 py-0.5 rounded text-[10px]">
                    Enter
                  </kbd>
                </button>

                {/* Save Edits (Ctrl+S) */}
                <button
                  type="button"
                  onClick={handleSaveEdits}
                  disabled={isResolving}
                  className="flex items-center justify-center gap-1.5 bg-white hover:bg-slate-100 text-slate-900 font-mono text-xs font-bold py-3 px-4 rounded-xl border border-[#CBD5E1] transition-colors disabled:opacity-50 cursor-pointer"
                >
                  <Save className="w-4 h-4 text-slate-600" />
                  <span>Save Edits</span>
                  <kbd className="ml-1 bg-slate-100 text-slate-600 border border-slate-300 px-1.5 py-0.5 rounded text-[10px]">
                    Ctrl+S
                  </kbd>
                </button>
              </div>

              <div className="text-[11px] font-mono text-slate-500 text-center">
                Advances automatically to the next flagged receipt upon approval.
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
