import { create } from 'zustand';
import { ReceiptDetail } from '../types';

interface ConsoleState {
  // Navigation tab state
  activeNav: 'overview' | 'review' | 'ledger' | 'health';
  setActiveNav: (nav: 'overview' | 'review' | 'ledger' | 'health') => void;

  // Review Desk state
  activeQueueIndex: number;
  setActiveQueueIndex: (index: number) => void;
  nextQueueItem: (total: number) => void;
  prevQueueItem: () => void;

  // Audit Ledger state
  selectedReceiptRowIndex: number;
  setSelectedReceiptRowIndex: (index: number) => void;
  ledgerSearch: string;
  setLedgerSearch: (search: string) => void;
  typeFilter: 'ALL' | 'PRINTED' | 'HANDWRITTEN';
  setTypeFilter: (filter: 'ALL' | 'PRINTED' | 'HANDWRITTEN') => void;
  dateStartFilter: string;
  setDateStartFilter: (date: string) => void;
  dateEndFilter: string;
  setDateEndFilter: (date: string) => void;

  // Inspector Drawer state
  inspectedReceipt: ReceiptDetail | null;
  isDrawerOpen: boolean;
  openInspector: (receipt: ReceiptDetail) => void;
  closeInspector: () => void;

  // Inline Modals/Panels (Inline, never modal popups)
  isShortcutsPanelOpen: boolean;
  toggleShortcutsPanel: () => void;
  closeShortcutsPanel: () => void;

  isUploadDrawerOpen: boolean;
  toggleUploadDrawer: () => void;
  closeUploadDrawer: () => void;

  // Duplicate conflict state
  conflictAlert: {
    existingReceiptId: string;
    message?: string;
  } | null;
  setConflictAlert: (alert: { existingReceiptId: string; message?: string } | null) => void;

  // Overview date parameters
  selectedYear: number;
  selectedMonth: number;
  setSelectedPeriod: (year: number, month: number) => void;
}

export const useConsoleStore = create<ConsoleState>((set) => ({
  activeNav: 'overview',
  setActiveNav: (activeNav) => set({ activeNav }),
  activeQueueIndex: 0,
  setActiveQueueIndex: (index: number) => set({ activeQueueIndex: Math.max(0, index) }),
  nextQueueItem: (total: number) =>
    set((state) => ({
      activeQueueIndex: Math.min(Math.max(0, total - 1), state.activeQueueIndex + 1),
    })),
  prevQueueItem: () =>
    set((state) => ({
      activeQueueIndex: Math.max(0, state.activeQueueIndex - 1),
    })),

  selectedReceiptRowIndex: 0,
  setSelectedReceiptRowIndex: (index: number) => set({ selectedReceiptRowIndex: index }),
  ledgerSearch: '',
  setLedgerSearch: (search: string) => set({ ledgerSearch: search }),
  typeFilter: 'ALL',
  setTypeFilter: (typeFilter) => set({ typeFilter }),
  dateStartFilter: '',
  setDateStartFilter: (dateStartFilter) => set({ dateStartFilter }),
  dateEndFilter: '',
  setDateEndFilter: (dateEndFilter) => set({ dateEndFilter }),

  inspectedReceipt: null,
  isDrawerOpen: false,
  openInspector: (receipt: ReceiptDetail) => set({ inspectedReceipt: receipt, isDrawerOpen: true }),
  closeInspector: () => set({ isDrawerOpen: false }),

  isShortcutsPanelOpen: false,
  toggleShortcutsPanel: () => set((state) => ({ isShortcutsPanelOpen: !state.isShortcutsPanelOpen })),
  closeShortcutsPanel: () => set({ isShortcutsPanelOpen: false }),

  isUploadDrawerOpen: false,
  toggleUploadDrawer: () => set((state) => ({ isUploadDrawerOpen: !state.isUploadDrawerOpen })),
  closeUploadDrawer: () => set({ isUploadDrawerOpen: false }),

  conflictAlert: null,
  setConflictAlert: (conflictAlert) => set({ conflictAlert }),

  selectedYear: 2026,
  selectedMonth: 10,
  setSelectedPeriod: (year: number, month: number) =>
    set({ selectedYear: year, selectedMonth: month }),
}));
