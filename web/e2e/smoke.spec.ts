import { test, expect } from '@playwright/test';

test.describe('ReceiptLedger Operations Console Smoke Workflow', () => {
  test('login -> seed demo -> approve item with Enter -> search ledger with / -> open drawer with Space -> reset ledger', async ({ page }) => {
    // ── 1. Login ─────────────────────────────────────────────────────────────
    await page.goto('/');

    // Check login view presence
    await expect(page.getByText(/RECEIPTLEDGER OPERATIONS CONSOLE/i)).toBeVisible();
    await expect(page.getByText(/Desktop Authentication Gateway/i)).toBeVisible();

    // Fill credentials
    await page.getByPlaceholder('operator@receiptledger.com').fill('user@receiptledger.com');
    await page.getByPlaceholder('••••••••').fill('demo1234');
    await page.getByRole('button', { name: /Sign In to Console/i }).click();

    // ── 2. Console Loaded & Operational Status ──────────────────────────────
    await expect(page.getByText('RECEIPTLEDGER DESKTOP CONSOLE')).toBeVisible();
    await expect(page.getByText('ALL ENGINES OPERATIONAL')).toBeVisible({ timeout: 10000 });

    // ── 3. Seed Demo Data ───────────────────────────────────────────────────
    const seedButton = page.getByRole('button', { name: /Seed Demo/i });
    await expect(seedButton).toBeVisible();
    await seedButton.click();

    // Wait for overview KPI cards to reflect 148 receipts
    await expect(page.getByText(/148 Receipts/i)).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(/PKR 184,250\.00/i)).toBeVisible();

    // ── 4. Approve Active Item with Enter ───────────────────────────────────
    // Focus candidate name input in Review Desk
    const candidateInput = page.locator('input[data-triage-field="true"]').first();
    await expect(candidateInput).toBeVisible();
    await candidateInput.focus();

    // Press Enter to confirm & accept active item
    await page.keyboard.press('Enter');

    // Queue position should advance from 1 to 2
    await expect(page.getByText(/Queue Position:/i)).toBeVisible();

    // ── 5. Search Ledger with "/" ───────────────────────────────────────────
    // Blur any active input
    await page.locator('body').click();

    // Press "/" global hotkey
    await page.keyboard.press('/');

    const searchInput = page.getByPlaceholder(/Search merchant, items.../i);
    await expect(searchInput).toBeFocused();

    // Type query into search
    await searchInput.fill('Imtiaz');
    await page.waitForTimeout(500);

    // ── 6. Open Inspector Drawer with Space ─────────────────────────────────
    // Blur search input by pressing Escape or clicking table container
    await page.locator('table').click();

    // Press Space to open inspector drawer for selected row
    await page.keyboard.press('Space');

    // Slide-out drawer should become visible
    await expect(page.getByRole('dialog')).toBeVisible();
    await expect(page.getByText(/Line Items/i)).toBeVisible();

    // Dismiss drawer with Escape
    await page.keyboard.press('Escape');
    await expect(page.getByRole('dialog')).not.toBeVisible();

    // ── 7. Reset Ledger (Two-Step Inline Confirmation) ──────────────────────
    const resetBtn = page.getByRole('button', { name: /Reset Ledger/i });
    await resetBtn.click();

    // Confirm inline
    const confirmBtn = page.getByRole('button', { name: /Confirm Reset\?/i });
    await expect(confirmBtn).toBeVisible();
    await confirmBtn.click();

    // Verify zero data states
    await expect(page.getByText(/0 Receipts/i)).toBeVisible({ timeout: 10000 });
    await expect(page.getByText(/PKR 0\.00/i)).toBeVisible();
    await expect(page.getByText(/Human Review Queue Cleared/i)).toBeVisible();
    await expect(page.getByText(/No Receipts Found/i)).toBeVisible();
  });
});
