/**
 * ReceiptLedger Formatter Utilities
 * Formats currencies, dates, numbers, and confidence percentages.
 */

/**
 * Format currency in Pakistani Rupees (PKR) using en-PK locale with fallback.
 */
export function formatPKR(amount: number | null | undefined): string {
  if (amount === null || amount === undefined || isNaN(amount)) {
    return 'PKR 0.00';
  }

  try {
    const formatted = new Intl.NumberFormat('en-PK', {
      style: 'currency',
      currency: 'PKR',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);

    // Some browsers format as "PKR 184,250.00" or "Rs 184,250.00"
    // Normalize to crisp "PKR X,XXX.XX"
    return formatted.replace(/^Rs\.?\s?/, 'PKR ');
  } catch {
    return `PKR ${amount.toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }
}

/**
 * Format raw numbers with tabular formatting (e.g. 184,250)
 */
export function formatNumber(value: number | null | undefined): string {
  if (value === null || value === undefined || isNaN(value)) {
    return '0';
  }
  return value.toLocaleString('en-US');
}

/**
 * Format percentage (e.g. 96.2%)
 */
export function formatPercent(value: number | null | undefined, decimals = 1): string {
  if (value === null || value === undefined || isNaN(value)) {
    return '0.0%';
  }
  return `${value.toFixed(decimals)}%`;
}

/**
 * Format dates in ISO YYYY-MM-DD or friendly tabular format
 */
export function formatDate(dateString: string | null | undefined): string {
  if (!dateString) return '—';
  try {
    const d = new Date(dateString);
    if (isNaN(d.getTime())) return dateString;
    return d.toISOString().split('T')[0];
  } catch {
    return dateString;
  }
}

/**
 * Format timestamp into readable time for run logs
 */
export function formatDateTime(isoString: string | null | undefined): string {
  if (!isoString) return '—';
  try {
    const d = new Date(isoString);
    if (isNaN(d.getTime())) return isoString;
    return d.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });
  } catch {
    return isoString;
  }
}
