import { describe, it, expect } from 'vitest';
import { getConfidenceTier } from '../lib/adapter';

describe('Confidence Tier Thresholds', () => {
  it('classifies confidence >= 0.85 as high/verified (green/neutral)', () => {
    const high = getConfidenceTier(0.92);
    expect(high.tier).toBe('high');
    expect(high.label).toBe('Verified');
    expect(high.percent).toBe(92);
    expect(high.badgeClasses).toContain('bg-emerald-100');
    expect(high.badgeClasses).toContain('text-emerald-800');

    // Boundary at exact 0.85
    const exact = getConfidenceTier(0.85);
    expect(exact.tier).toBe('high');
    expect(exact.label).toBe('Verified');
  });

  it('classifies confidence < 0.85 and >= 0.60 as warning state (amber)', () => {
    const warning = getConfidenceTier(0.745);
    expect(warning.tier).toBe('warning');
    expect(warning.label).toBe('Warning (<85%)');
    expect(warning.percent).toBe(74.5);
    expect(warning.badgeClasses).toContain('bg-amber-100');
    expect(warning.badgeClasses).toContain('text-amber-900');

    // Boundary at 0.849
    const upperBoundary = getConfidenceTier(0.849);
    expect(upperBoundary.tier).toBe('warning');
  });

  it('classifies confidence < 0.60 as low state (red)', () => {
    const low = getConfidenceTier(0.55);
    expect(low.tier).toBe('low');
    expect(low.label).toBe('Low (<60%)');
    expect(low.percent).toBe(55);
    expect(low.badgeClasses).toContain('bg-red-100');
    expect(low.badgeClasses).toContain('text-red-900');
  });

  it('handles percentages provided as 0-100 scale', () => {
    const res = getConfidenceTier(94.5);
    expect(res.tier).toBe('high');
    expect(res.percent).toBe(94.5);
  });
});
