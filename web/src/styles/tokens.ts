/**
 * ReceiptLedger Design Tokens
 *
 * Visual Constraints:
 * 1. ZERO GRADIENTS (Solid colors only)
 * 2. ZERO GLASSMORPHISM (No backdrop-filter or blur)
 * 3. 1px crisp borders (#CBD5E1)
 * 4. High-contrast typography & tabular numbers
 */

export const tokens = {
  colors: {
    // Surfaces
    background: '#F8FAFC',
    surface: '#FFFFFF',
    surfaceSubtle: '#F1F5F9',
    surfaceMuted: '#E2E8F0',
    surfaceDark: '#0F172A',
    surfaceActiveBlack: '#000000',

    // Borders (1px crisp solid)
    border: '#CBD5E1',
    borderLight: '#E2E8F0',
    borderDark: '#1E293B',
    borderFocus: '#000000',

    // Functional State Colors
    textPrimary: '#0F172A',
    textSecondary: '#475569',
    textMuted: '#64748B',

    // Severity / Status Accents (Solid only)
    success: {
      bg: '#DCFCE7',
      text: '#166534',
      border: '#86EFAC',
      solid: '#16A34A',
    },
    warning: {
      bg: '#FEF3C7',
      text: '#92400E',
      border: '#FCD34D',
      solid: '#F59E0B',
    },
    critical: {
      bg: '#FEE2E2',
      text: '#991B1B',
      border: '#FCA5A5',
      solid: '#DC2626',
    },
    neutral: {
      bg: '#F1F5F9',
      text: '#334155',
      border: '#CBD5E1',
      solid: '#64748B',
    },
  },

  radii: {
    none: '0px',
    sm: '4px',
    md: '6px',
    lg: '8px',
    xl: '12px',
    full: '9999px',
  },

  typography: {
    sans: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    mono: '"JetBrains Mono", Fira Code, Consolas, monospace',
    urdu: '"Noto Nastaliq Urdu", "Noto Sans Arabic", Tahoma, sans-serif',
  },

  confidence: {
    highThreshold: 0.85,
    lowThreshold: 0.60,
  },
} as const;

export type ThemeTokens = typeof tokens;
