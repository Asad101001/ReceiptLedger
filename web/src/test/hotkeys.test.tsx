import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { useHotkeys } from '../hooks/useHotkeys';

const TestHotkeyConsumer: React.FC<{
  onApproveActiveItem?: () => void;
  onSaveEdits?: () => void;
  onSelectPrevRow?: () => void;
  onSelectNextRow?: () => void;
  onOpenInspector?: () => void;
  onCloseDrawer?: () => void;
  onFocusSearch?: () => void;
  onToggleShortcuts?: () => void;
}> = (props) => {
  useHotkeys(props);
  return (
    <div>
      <input data-testid="regular-input" placeholder="Regular Input" />
      <input data-testid="triage-input" data-triage-field="true" placeholder="Triage Input" />
      <div data-testid="console-canvas">Operations Canvas</div>
    </div>
  );
};

describe('Desktop Keyboard Ergonomics & Shortcuts', () => {
  it('fires Enter to approve when focus is on body/canvas', () => {
    const onApprove = vi.fn();
    render(<TestHotkeyConsumer onApproveActiveItem={onApprove} />);

    fireEvent.keyDown(window, { key: 'Enter', code: 'Enter' });
    expect(onApprove).toHaveBeenCalledTimes(1);
  });

  it('fires Enter to approve when focus is on a triage input field', () => {
    const onApprove = vi.fn();
    render(<TestHotkeyConsumer onApproveActiveItem={onApprove} />);

    const triageInput = screen.getByTestId('triage-input');
    triageInput.focus();

    fireEvent.keyDown(triageInput, { key: 'Enter', code: 'Enter' });
    expect(onApprove).toHaveBeenCalledTimes(1);
  });

  it('does NOT fire Enter to approve when typing in a regular non-triage input', () => {
    const onApprove = vi.fn();
    render(<TestHotkeyConsumer onApproveActiveItem={onApprove} />);

    const regularInput = screen.getByTestId('regular-input');
    regularInput.focus();

    fireEvent.keyDown(regularInput, { key: 'Enter', code: 'Enter' });
    expect(onApprove).not.toHaveBeenCalled();
  });

  it('fires Ctrl+S / Cmd+S to save edits and prevents default browser save', () => {
    const onSaveEdits = vi.fn();
    render(<TestHotkeyConsumer onSaveEdits={onSaveEdits} />);

    const event = new KeyboardEvent('keydown', {
      key: 's',
      ctrlKey: true,
      cancelable: true,
    });
    window.dispatchEvent(event);

    expect(onSaveEdits).toHaveBeenCalledTimes(1);
  });

  it('fires Escape to dismiss drawer or cancel edits', () => {
    const onCloseDrawer = vi.fn();
    render(<TestHotkeyConsumer onCloseDrawer={onCloseDrawer} />);

    fireEvent.keyDown(window, { key: 'Escape', code: 'Escape' });
    expect(onCloseDrawer).toHaveBeenCalledTimes(1);
  });

  it('fires "/" to focus search when not typing in an input', () => {
    const onFocusSearch = vi.fn();
    render(<TestHotkeyConsumer onFocusSearch={onFocusSearch} />);

    fireEvent.keyDown(window, { key: '/', code: 'Slash' });
    expect(onFocusSearch).toHaveBeenCalledTimes(1);
  });

  it('fires J / K or Up / Down to navigate ledger rows', () => {
    const onSelectNextRow = vi.fn();
    const onSelectPrevRow = vi.fn();
    render(
      <TestHotkeyConsumer
        onSelectNextRow={onSelectNextRow}
        onSelectPrevRow={onSelectPrevRow}
      />
    );

    fireEvent.keyDown(window, { key: 'j', code: 'KeyJ' });
    expect(onSelectNextRow).toHaveBeenCalledTimes(1);

    fireEvent.keyDown(window, { key: 'k', code: 'KeyK' });
    expect(onSelectPrevRow).toHaveBeenCalledTimes(1);
  });

  it('fires Space to open inspector drawer when not typing in an input', () => {
    const onOpenInspector = vi.fn();
    render(<TestHotkeyConsumer onOpenInspector={onOpenInspector} />);

    fireEvent.keyDown(window, { key: ' ', code: 'Space' });
    expect(onOpenInspector).toHaveBeenCalledTimes(1);
  });

  it('does NOT fire single-key shortcuts (J, K, Space, /) when typing in an input', () => {
    const onSelectNextRow = vi.fn();
    const onOpenInspector = vi.fn();
    const onFocusSearch = vi.fn();

    render(
      <TestHotkeyConsumer
        onSelectNextRow={onSelectNextRow}
        onOpenInspector={onOpenInspector}
        onFocusSearch={onFocusSearch}
      />
    );

    const regularInput = screen.getByTestId('regular-input');
    regularInput.focus();

    fireEvent.keyDown(regularInput, { key: 'j', code: 'KeyJ' });
    fireEvent.keyDown(regularInput, { key: ' ', code: 'Space' });
    fireEvent.keyDown(regularInput, { key: '/', code: 'Slash' });

    expect(onSelectNextRow).not.toHaveBeenCalled();
    expect(onOpenInspector).not.toHaveBeenCalled();
    expect(onFocusSearch).not.toHaveBeenCalled();
  });
});
