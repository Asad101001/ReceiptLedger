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

  it('renders login screen with brand header and empty credentials', () => {
    renderWithClient(<LoginView />);

    expect(screen.getByText('RECEIPTLEDGER OPERATIONS CONSOLE')).toBeInTheDocument();
    expect(screen.getByText('Desktop Authentication Gateway')).toBeInTheDocument();

    const emailInput = screen.getByPlaceholderText('operator@receiptledger.com') as HTMLInputElement;
    const passwordInput = screen.getByPlaceholderText('••••••••') as HTMLInputElement;

    // Must not be prefilled by default
    expect(emailInput.value).toBe('');
    expect(passwordInput.value).toBe('');

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
      setAuthToken('mock-jwt-token-2026');
      return {
        access_token: 'mock-jwt-token-2026',
        token_type: 'bearer',
        expires_in: 86400,
        user: {
          user_id: 'usr_demo_7721',
          email: creds.email,
          full_name: 'Demo Household Manager',
          role: 'admin',
          is_authenticated: true,
        },
      };
    });

    vi.spyOn(api, 'getCurrentUser').mockResolvedValue({
      user_id: 'usr_demo_7721',
      email: 'user@receiptledger.com',
      full_name: 'Demo Household Manager',
      role: 'admin',
      is_authenticated: true,
      created_at: '2026-01-01T00:00:00Z',
    });

    renderWithClient(<LoginView />);

    const emailInput = screen.getByPlaceholderText('operator@receiptledger.com');
    const passwordInput = screen.getByPlaceholderText('••••••••');
    const submitBtn = screen.getByRole('button', { name: /Sign In to Console/i });

    fireEvent.change(emailInput, { target: { value: 'user@receiptledger.com' } });
    fireEvent.change(passwordInput, { target: { value: 'demo1234' } });
    fireEvent.click(submitBtn);

    await waitFor(() => {
      expect(localStorage.getItem('receiptledger_access_token')).toBe('mock-jwt-token-2026');
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
    fireEvent.change(passwordInput, { target: { value: 'wrongpassword' } });
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

    // Offline dev mode button is available during network failure
    const offlineDevBtn = screen.getByRole('button', { name: /Enter Offline Dev Mode/i });
    expect(offlineDevBtn).toBeInTheDocument();

    fireEvent.click(offlineDevBtn);

    // Safety Requirement:
    // 1. Must NOT store a mock token in receiptledger_access_token
    expect(localStorage.getItem('receiptledger_access_token')).toBeNull();
    // 2. Must keep mock state separate under receiptledger_dev_mock_session
    expect(localStorage.getItem('receiptledger_dev_mock_session')).toBe('true');
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
