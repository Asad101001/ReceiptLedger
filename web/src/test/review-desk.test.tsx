import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ReviewDesk } from '../features/review-desk/ReviewDesk';
import { mockReviewQueue } from './mocks/handlers';

describe('Workspace A: Human-in-the-Loop Review Desk', () => {
  it('renders active item details, raw OCR, and color-coded confidence pill', () => {
    const onResolve = vi.fn().mockResolvedValue(undefined);
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={onResolve}
        isResolving={false}
      />
    );

    // Verify merchant and raw text
    expect(screen.getByText('Chaudhry Sabzi & Fruit Store')).toBeInTheDocument();
    expect(screen.getByText('129728 WITHA PER KG 0.640')).toBeInTheDocument();

    // Verify candidate name input
    const nameInput = screen.getByDisplayValue('Sweet Melon');
    expect(nameInput).toBeInTheDocument();

    // Verify confidence pill (<85% warning state)
    expect(screen.getByText(/74\.5%/)).toBeInTheDocument();
    expect(screen.getByText(/Warning \(<85%\)/)).toBeInTheDocument();

    // Verify queue position counter (1 of 3)
    expect(screen.getByText('1')).toBeInTheDocument();
    expect(screen.getByText('3')).toBeInTheDocument();
  });

  it('triggers 1-Click Accept with correct payload', async () => {
    const onResolve = vi.fn().mockResolvedValue(undefined);
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={onResolve}
        isResolving={false}
      />
    );

    const acceptButton = screen.getByRole('button', { name: /Confirm & Accept/i });
    fireEvent.click(acceptButton);

    expect(onResolve).toHaveBeenCalledTimes(1);
    expect(onResolve).toHaveBeenCalledWith(
      '7a79f40f-3047-4d76-a577-a41a58af9a56',
      expect.objectContaining({
        confirmed_name: 'Sweet Melon',
        action: 'ACCEPTED',
      })
    );
  });

  it('triggers Save Edits with corrected fields and EDITED action', async () => {
    const onResolve = vi.fn().mockResolvedValue(undefined);
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={onResolve}
        isResolving={false}
      />
    );

    const nameInput = screen.getByDisplayValue('Sweet Melon');
    fireEvent.change(nameInput, { target: { value: 'Organic Sweet Melon' } });

    const saveButton = screen.getByRole('button', { name: /Save Edits/i });
    fireEvent.click(saveButton);

    expect(onResolve).toHaveBeenCalledTimes(1);
    expect(onResolve).toHaveBeenCalledWith(
      '7a79f40f-3047-4d76-a577-a41a58af9a56',
      expect.objectContaining({
        confirmed_name: 'Organic Sweet Melon',
        action: 'EDITED',
        confirmed_quantity: 0.64,
        confirmed_unit_price: 199.0,
      })
    );
  });

  it('displays clean zero-data empty state when review queue is cleared', () => {
    render(
      <ReviewDesk
        queueItems={[]}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
      />
    );

    expect(screen.getByText(/Human Review Queue Cleared/i)).toBeInTheDocument();
    expect(screen.getByText(/100% Ingested Line Items Verified/i)).toBeInTheDocument();
  });

  it('operates zoom controls: zoom in, zoom out, and reset to 100%', () => {
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
      />
    );

    // Initial zoom 150%
    expect(screen.getByText('150%')).toBeInTheDocument();

    // Zoom in (+25%) -> 175%
    const zoomInBtn = screen.getByTitle(/Zoom In/i);
    fireEvent.click(zoomInBtn);
    expect(screen.getByText('175%')).toBeInTheDocument();

    // Zoom out (-25%) -> 150%
    const zoomOutBtn = screen.getByTitle(/Zoom Out/i);
    fireEvent.click(zoomOutBtn);
    expect(screen.getByText('150%')).toBeInTheDocument();

    // Reset 100%
    const resetZoomBtn = screen.getByTitle(/Reset 100%/i);
    fireEvent.click(resetZoomBtn);
    expect(screen.getByText('100%')).toBeInTheDocument();
  });

  it('renders 2px solid bounding box highlight for active snippet without glowing or gradients', () => {
    const { container } = render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
      />
    );

    expect(screen.getByText('ACTIVE SNIPPET')).toBeInTheDocument();

    // Bounding box border-2 check
    const bboxEl = container.querySelector('.border-2.border-red-600');
    expect(bboxEl).toBeInTheDocument();

    // Non-negotiable design constraint: zero gradients, zero backdrop-filter
    expect(container.innerHTML).not.toContain('gradient');
    expect(container.innerHTML).not.toContain('backdrop-filter');
    expect(container.innerHTML).not.toContain('backdrop-blur');
  });

  it('handles missing image gracefully with informative fallback card', () => {
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
      />
    );

    const img = screen.getByAltText('Receipt Scan');
    fireEvent.error(img);

    expect(screen.getByText(/Receipt scan unavailable/i)).toBeInTheDocument();
    expect(screen.getByText(/Triage details are preserved/i)).toBeInTheDocument();
  });

  it('clearly labels offline demo mode when isMockMode is true', () => {
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
        isMockMode={true}
      />
    );

    expect(screen.getByText('OFFLINE DEMO QUEUE')).toBeInTheDocument();
  });

  it('renders receipt preview image from receipt_image_url without network requests', () => {
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
        isMockMode={true}
      />
    );

    const img = screen.getByAltText('Receipt Scan') as HTMLImageElement;
    expect(img).toBeInTheDocument();
    expect(img.src).toContain('data:image/svg+xml');
  });

  it('advances queue and updates counter on Confirm & Accept until cleared state, then reloads', async () => {
    // Harness component simulating stateful queue progression
    const StatefulQueueHarness: React.FC = () => {
      const [items, setItems] = React.useState(mockReviewQueue);
      const [activeIndex, setActiveIndex] = React.useState(0);

      const handleResolve = async (queueId: string) => {
        setItems((prev) => prev.filter((i) => (i.queue_id || i.id) !== queueId));
        setActiveIndex(0);
      };

      const handleReload = () => {
        setItems([...mockReviewQueue]);
        setActiveIndex(0);
      };

      return (
        <ReviewDesk
          queueItems={items}
          activeIndex={activeIndex}
          onSelectIndex={setActiveIndex}
          onResolveItem={handleResolve}
          isResolving={false}
          isMockMode={true}
          onReloadMockQueue={handleReload}
        />
      );
    };

    render(<StatefulQueueHarness />);

    // Step 1: Initial item 1 of 3
    expect(screen.getByText('1')).toBeInTheDocument();
    expect(screen.getByText('3')).toBeInTheDocument();
    expect(screen.getByText('Chaudhry Sabzi & Fruit Store')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Sweet Melon')).toBeInTheDocument();

    // Confirm & Accept Item 1
    const acceptBtn1 = screen.getByRole('button', { name: /Confirm & Accept/i });
    fireEvent.click(acceptBtn1);

    // Step 2: Advances to item 2 (now 1 of 2)
    expect(await screen.findByText('Javed Nihari Restaurant')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Nalli Nihari (Half)')).toBeInTheDocument();
    expect(screen.getByText('1 NALLI NIHARI HLF 1150')).toBeInTheDocument();

    // Confirm & Accept Item 2
    const acceptBtn2 = screen.getByRole('button', { name: /Confirm & Accept/i });
    fireEvent.click(acceptBtn2);

    // Step 3: Advances to item 3 (now 1 of 1)
    expect(await screen.findByText('Al-Madina Departmental Store')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Shan Biryani Masala')).toBeInTheDocument();
    expect(screen.getByText('2X SHAN BIRYANI MASALA 180')).toBeInTheDocument();

    // Confirm & Accept Item 3
    const acceptBtn3 = screen.getByRole('button', { name: /Confirm & Accept/i });
    fireEvent.click(acceptBtn3);

    // Step 4: Queue is now cleared
    expect(await screen.findByText(/Human Review Queue Cleared/i)).toBeInTheDocument();
    expect(screen.getByText(/100% Ingested Line Items Verified/i)).toBeInTheDocument();

    // Step 5: Reload mock review queue from cleared state
    const reloadBtn = screen.getByRole('button', { name: /Reload Mock Review Queue/i });
    fireEvent.click(reloadBtn);

    // Step 6: Queue is re-populated with 3 items again
    expect(await screen.findByText('Chaudhry Sabzi & Fruit Store')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Sweet Melon')).toBeInTheDocument();
  });

  it('displays full triage form fields: candidate input, qty, unit, unit price, total price, and action buttons', () => {
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={0}
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
        isMockMode={true}
      />
    );

    // Triage inputs
    const candidateInput = screen.getByDisplayValue('Sweet Melon');
    expect(candidateInput).toBeInTheDocument();

    const qtyInput = screen.getByDisplayValue('0.64');
    expect(qtyInput).toBeInTheDocument();

    const unitInput = screen.getByDisplayValue('kg');
    expect(unitInput).toBeInTheDocument();

    const unitPriceInput = screen.getByDisplayValue('199');
    expect(unitPriceInput).toBeInTheDocument();

    // Reconciled total
    expect(screen.getByText(/127\.36/)).toBeInTheDocument();

    // Action buttons
    expect(screen.getByRole('button', { name: /Confirm & Accept/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Save Edits/i })).toBeInTheDocument();
  });

  it('immediately renders missing-image fallback card in mock mode when receipt_image_url is empty', () => {
    render(
      <ReviewDesk
        queueItems={mockReviewQueue}
        activeIndex={1} // Item 2 has receipt_image_url: ''
        onSelectIndex={vi.fn()}
        onResolveItem={vi.fn()}
        isResolving={false}
        isMockMode={true}
      />
    );

    expect(screen.getByText('Javed Nihari Restaurant')).toBeInTheDocument();
    expect(screen.getByText(/Receipt scan unavailable/i)).toBeInTheDocument();
    expect(screen.getByText(/Triage details are preserved from database record/i)).toBeInTheDocument();
  });
});
