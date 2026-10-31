import React, { useState, useEffect, useRef } from 'react';
import Header from './components/Header';
import KpiMetricsRow from './components/KpiMetricsRow';
import WorkspaceA_ReviewDesk from './components/WorkspaceA_ReviewDesk';
import WorkspaceB_AuditLedger from './components/WorkspaceB_AuditLedger';
import BottomRibbon from './components/BottomRibbon';
import UploadReceiptModal from './components/UploadReceiptModal';
import KeyboardShortcutsModal from './components/KeyboardShortcutsModal';
import { api } from './services/api';

export default function App() {
  const [health, setHealth] = useState(null);
  const [overview, setOverview] = useState(null);
  const [queueItems, setQueueItems] = useState([]);
  const [activeQueueIndex, setActiveQueueIndex] = useState(0);
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  // Modals
  const [uploadModalOpen, setUploadModalOpen] = useState(false);
  const [shortcutsModalOpen, setShortcutsModalOpen] = useState(false);

  // Loading flags
  const [loadingSeed, setLoadingSeed] = useState(false);
  const [loadingReset, setLoadingReset] = useState(false);
  const [toast, setToast] = useState(null);

  const searchInputRef = useRef(null);

  // Initial Data Fetch
  const loadData = async () => {
    try {
      const [hData, ovData, qData] = await Promise.all([
        api.getHealth(),
        api.getDashboardOverview(2026, 10),
        api.getReviewQueue('UNRESOLVED'),
      ]);
      setHealth(hData);
      setOverview(ovData);
      setQueueItems(qData || []);
    } catch (err) {
      console.error('Error loading dashboard data:', err);
    }
  };

  useEffect(() => {
    loadData();
  }, [refreshTrigger]);

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3500);
  };

  // Seed Demo Data (POST /api/v1/dashboard/seed-demo)
  const handleSeedDemo = async () => {
    setLoadingSeed(true);
    try {
      const res = await api.seedDemoData();
      showToast('Seeded 148 realistic receipts & 7 review items.');
      setRefreshTrigger((prev) => prev + 1);
      setActiveQueueIndex(0);
    } catch (err) {
      console.error('Seed demo error:', err);
      showToast(err.message || 'Failed to seed demo data', 'error');
    } finally {
      setLoadingSeed(false);
    }
  };

  // Reset Ledger (POST /api/v1/dashboard/reset)
  const handleResetLedger = async () => {
    if (!window.confirm('Reset ledger to zero-data state? All receipts and line items will be purged.')) {
      return;
    }
    setLoadingReset(true);
    try {
      await api.resetLedger();
      showToast('Ledger reset to zero-data initial state.');
      setRefreshTrigger((prev) => prev + 1);
      setActiveQueueIndex(0);
    } catch (err) {
      console.error('Reset ledger error:', err);
      showToast(err.message || 'Failed to reset ledger', 'error');
    } finally {
      setLoadingReset(false);
    }
  };

  // Review item resolved callback
  const handleItemResolved = (queueId, action) => {
    // Remove resolved item from local queue or advance index
    setQueueItems((prev) => {
      const updated = prev.filter((item) => (item.id || item.queue_id) !== queueId);
      if (activeQueueIndex >= updated.length) {
        setActiveQueueIndex(Math.max(0, updated.length - 1));
      }
      return updated;
    });
    // Trigger global refresh so overview and ledger update immediately
    setRefreshTrigger((prev) => prev + 1);
  };

  // Upload success
  const handleUploadSuccess = () => {
    showToast('Receipt processed through ingestion pipeline.');
    setRefreshTrigger((prev) => prev + 1);
  };

  // Global Keyboard Shortcuts (Section 5)
  useEffect(() => {
    const handleGlobalKeyDown = (e) => {
      // Don't intercept if currently focused on form elements
      if (['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) {
        if (e.key === 'Escape') {
          e.target.blur();
        }
        return;
      }

      // Key '/' -> Jump focus to Audit Ledger Search input
      if (e.key === '/') {
        e.preventDefault();
        if (searchInputRef.current) {
          searchInputRef.current.focus();
          searchInputRef.current.select();
        }
      }

      // Key '?' -> Open keyboard shortcuts cheat sheet
      if (e.key === '?') {
        e.preventDefault();
        setShortcutsModalOpen((prev) => !prev);
      }
    };

    window.addEventListener('keydown', handleGlobalKeyDown);
    return () => window.removeEventListener('keydown', handleGlobalKeyDown);
  }, []);

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 flex flex-col font-sans">
      {/* 1. Header with Engines status & Quick Action Controls */}
      <Header
        health={health}
        onSeedDemo={handleSeedDemo}
        onResetLedger={handleResetLedger}
        onOpenUpload={() => setUploadModalOpen(true)}
        onOpenShortcuts={() => setShortcutsModalOpen(true)}
        loadingSeed={loadingSeed}
        loadingReset={loadingReset}
      />

      {/* Floating Toast Notification */}
      {toast && (
        <div className="fixed top-14 right-5 z-50 animate-in fade-in slide-in-from-top-2 duration-150">
          <div className={`px-4 py-2.5 rounded font-mono text-xs font-semibold shadow-lg border ${
            toast.type === 'error'
              ? 'bg-red-900 text-white border-red-700'
              : 'bg-emerald-900 text-white border-emerald-700'
          }`}>
            {toast.message}
          </div>
        </div>
      )}

      {/* Main Desktop Container (Optimized for 1280px to 1920px+ Fixed-Fluid viewports) */}
      <main className="flex-1 max-w-[1920px] w-full mx-auto flex flex-col">
        {/* 2. Top KPI Stat Cards Row (148 Receipts, PKR 184,250.00, 7 Pending, 96.2% Accuracy) */}
        <KpiMetricsRow overview={overview} />

        {/* 3. Main Split Workspace: Workspace A (50%) + Workspace B (50%) */}
        <div className="flex-1 grid grid-cols-1 xl:grid-cols-2 gap-4 px-5 pb-4 min-h-[560px]">
          {/* WORKSPACE A: HUMAN-IN-THE-LOOP REVIEW DESK (50% Split) */}
          <WorkspaceA_ReviewDesk
            queueItems={queueItems}
            onItemResolved={handleItemResolved}
            onRefreshQueue={() => setRefreshTrigger((p) => p + 1)}
            activeQueueIndex={activeQueueIndex}
            setActiveQueueIndex={setActiveQueueIndex}
          />

          {/* WORKSPACE B: INGESTION AUDIT LEDGER (50% Split) */}
          <WorkspaceB_AuditLedger
            searchInputRef={searchInputRef}
            refreshTrigger={refreshTrigger}
          />
        </div>

        {/* 4. Bottom Telemetry & Analytics Ribbon */}
        <div className="px-5 pb-5">
          <BottomRibbon
            overview={overview}
            refreshTrigger={refreshTrigger}
          />
        </div>
      </main>

      {/* Modals */}
      <UploadReceiptModal
        isOpen={uploadModalOpen}
        onClose={() => setUploadModalOpen(false)}
        onUploadSuccess={handleUploadSuccess}
      />

      <KeyboardShortcutsModal
        isOpen={shortcutsModalOpen}
        onClose={() => setShortcutsModalOpen(false)}
      />
    </div>
  );
}
