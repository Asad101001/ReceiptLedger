import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { LoginView } from '../features/auth/LoginView';
import { api, setAuthToken, ApiError } from '../api/client';
import { setDevMockSession } from '../hooks/useAuth';

function renderWithClient(ui: React.ReactElement) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      {ui}
    </QueryClientProvider>
  );
}

describe('Phase 2: Frontend Authentication & Login View', () => {
  beforeEach(() => {
    localStorage.clear();
    setAuthToken(null);
    setDevMockSession(false);
    vi.restoreAllMocks();
  });

  it('renders login screen with brand header and console subtitle', () => {
    renderWithClient(<LoginView />);

    expect(screen.getByRole('heading', { level: 1, name: /ReceiptLedger/i })).toBeInTheDocument();
    expect(screen.getByText('Operations Console & Audit Ledger')).toBeInTheDocument();

    const emailInput = screen.getByPlaceholderText('operator@receiptledger.com') as HTMLInputElement;
    const passwordInput = screen.getByPlaceholderText('••••••••') as HTMLInputElement;

    expect(emailInput).toBeInTheDocument();
    expect(passwordInput).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Sign In to Console/i })).toBeInTheDocument();
  });

  it('autofills demo credentials on development click', () => {
    renderWithClient(<LoginView />);

    const autofillBtn = screen.getByRole('button', { name: /Autofill/i });
    fireEvent.click(autofillBtn);

    const emailInput = screen.getByPlaceholderText('operator@receiptledger.com') as HTMLInputElement;
    const passwordInput = screen.getByPlaceholderText('••••••••') as HTMLInputElement;

    expect(emailInput.value).toBe('user@receiptledger.com');
    expect(passwordInput.value).toBe('demo1234');
  });

  it('submits valid credentials and triggers successful login', async () => {
    vi.spyOn(api, 'login').mockImplementation(async (creds) => {
      if (creds.email === 'user@receiptledger.com' && creds.password === 'demo1234') {
        setAuthToken('fake_jwt_token_for_test');
        return {
          access_token: 'fake_jwt_token_for_test',
          token_type: 'bearer',
          user: {
            id: 'usr_1',
            email: 'user@receiptledger.com',
            role: 'operator',
          },
        };
      }
      throw new ApiError('Invalid email or password.', 401);
    });

    renderWithClient(<LoginView />);

    const emailInput = screen.getByPlaceholderText('operator@receiptledger.com');
    const passwordInput = screen.getByPlaceholderText('••••••••');
    const submitBtn = screen.getByRole('button', { name: /Sign In to Console/i });

    fireEvent.change(emailInput, { target: { value: 'user@receiptledger.com' } });
    fireEvent.change(passwordInput, { target: { value: 'demo1234' } });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      expect(localStorage.getItem('receiptledger_access_token')).toBe('fake_jwt_token_for_test');
    });
  });

  it('displays user-friendly error banner on 401 invalid credentials', async () => {
    vi.spyOn(api, 'login').mockRejectedValueOnce(
      new ApiError('Invalid email or password.', 401)
    );

    renderWithClient(<LoginView />);

    const emailInput = screen.getByPlaceholderText('operator@receiptledger.com');
    const passwordInput = screen.getByPlaceholderText('••••••••');
    const submitBtn = screen.getByRole('button', { name: /Sign In to Console/i });

    fireEvent.change(emailInput, { target: { value: 'wrong@receiptledger.com' } });
    fireEvent.change(passwordInput, { target: { value: 'wrongpass' } });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      expect(screen.getByText(/Invalid email or password/i)).toBeInTheDocument();
    });

    // Token must not be stored
    expect(localStorage.getItem('receiptledger_access_token')).toBeNull();
  });

  it('displays clear gateway unavailable error when API network fails', async () => {
    vi.spyOn(api, 'login').mockRejectedValueOnce(
      new ApiError('Gateway connection unavailable (http://localhost:8000/api/v1). Ensure the backend server is running.', 0)
    );

    renderWithClient(<LoginView />);

    const emailInput = screen.getByPlaceholderText('operator@receiptledger.com');
    const passwordInput = screen.getByPlaceholderText('••••••••');
    const submitBtn = screen.getByRole('button', { name: /Sign In to Console/i });

    fireEvent.change(emailInput, { target: { value: 'user@receiptledger.com' } });
    fireEvent.change(passwordInput, { target: { value: 'demo1234' } });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      expect(screen.getByText(/Gateway connection unavailable/i)).toBeInTheDocument();
    });

    // Safety Requirement:
    // Must NOT store a mock token in receiptledger_access_token
    expect(localStorage.getItem('receiptledger_access_token')).toBeNull();
  });

  it('guarantees offline mock mode does not store or send Bearer tokens', async () => {
    // Attempting to set a mock token directly into setAuthToken must be blocked
    setAuthToken('dev_mock_token');
    expect(localStorage.getItem('receiptledger_access_token')).toBeNull();

    // Dev mock mode strictly uses separate storage
    setDevMockSession(true);
    expect(localStorage.getItem('receiptledger_dev_mock_session')).toBe('true');
    expect(localStorage.getItem('receiptledger_access_token')).toBeNull();

    // Resetting/logging out cleans up the separate mock state
    setDevMockSession(false);
    expect(localStorage.getItem('receiptledger_dev_mock_session')).toBeNull();
  });
});
