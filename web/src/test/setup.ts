import '@testing-library/jest-dom/vitest';
import { beforeAll, afterEach, afterAll } from 'vitest';
import { server } from './mocks/server';

// ── MSW Lifecycle ─────────────────────────────────────────────────────────────
beforeAll(() => {
  (server.listen as any)({ onUnhandledRequest: 'bypass' });
});
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

if (typeof window !== 'undefined') {
  // ── Mock ResizeObserver for Recharts ResponsiveContainer ─────────────────────
  (window as any).ResizeObserver = class ResizeObserver {
    observe() {}
    unobserve() {}
    disconnect() {}
  };

  // ── Mock window.matchMedia ───────────────────────────────────────────────────
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: (query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    }),
  });
}
