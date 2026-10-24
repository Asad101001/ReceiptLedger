import { useEffect } from 'react';

interface HotkeyHandlers {
  onApproveActiveItem?: () => void;
  onSaveEdits?: () => void;
  onSelectPrevRow?: () => void;
  onSelectNextRow?: () => void;
  onOpenInspector?: () => void;
  onCloseDrawer?: () => void;
  onFocusSearch?: () => void;
  onToggleShortcuts?: () => void;
}

export function useHotkeys({
  onApproveActiveItem,
  onSaveEdits,
  onSelectPrevRow,
  onSelectNextRow,
  onOpenInspector,
  onCloseDrawer,
  onFocusSearch,
  onToggleShortcuts,
}: HotkeyHandlers) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const activeEl = document.activeElement;
      const isInputFocused =
        activeEl instanceof HTMLInputElement ||
        activeEl instanceof HTMLTextAreaElement ||
        activeEl instanceof HTMLSelectElement;

      const isModifier = e.ctrlKey || e.metaKey;

      // ── 1. Ctrl+S / Cmd+S (Review Desk: Save Edits) ─────────────────────────
      if (isModifier && (e.key === 's' || e.key === 'S')) {
        e.preventDefault();
        onSaveEdits?.();
        return;
      }

      // ── 2. Escape: Dismiss Drawer / Cancel Edits ───────────────────────────
      if (e.key === 'Escape') {
        e.preventDefault();
        onCloseDrawer?.();
        return;
      }

      // ── 3. Global '/' key: Jump focus to search input ───────────────────────
      if (e.key === '/' && !isInputFocused) {
        e.preventDefault();
        onFocusSearch?.();
        return;
      }

      // ── 4. '?' key: Toggle Shortcuts Panel ─────────────────────────────────
      if (e.key === '?' && !isInputFocused) {
        e.preventDefault();
        onToggleShortcuts?.();
        return;
      }

      // If user is currently typing in an input, do not trigger single-key ledger navigations
      if (isInputFocused) {
        // If Enter is pressed inside the triage form, approve or submit
        if (e.key === 'Enter' && !isModifier) {
          const isTriageField = activeEl?.getAttribute('data-triage-field') === 'true';
          if (isTriageField) {
            e.preventDefault();
            onApproveActiveItem?.();
          }
        }
        return;
      }

      // ── 5. Enter/Return: Approve active item in Review Desk ──────────────────
      if (e.key === 'Enter') {
        e.preventDefault();
        onApproveActiveItem?.();
        return;
      }

      // ── 6. Up/Down or J/K: Select previous/next ledger row ──────────────────
      if (e.key === 'ArrowDown' || e.key === 'j' || e.key === 'J') {
        e.preventDefault();
        onSelectNextRow?.();
        return;
      }

      if (e.key === 'ArrowUp' || e.key === 'k' || e.key === 'K') {
        e.preventDefault();
        onSelectPrevRow?.();
        return;
      }

      // ── 7. Space: Open Inspector Drawer for selected row ───────────────────
      if (e.key === ' ' || e.code === 'Space') {
        e.preventDefault();
        onOpenInspector?.();
        return;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [
    onApproveActiveItem,
    onSaveEdits,
    onSelectPrevRow,
    onSelectNextRow,
    onOpenInspector,
    onCloseDrawer,
    onFocusSearch,
    onToggleShortcuts,
  ]);
}
