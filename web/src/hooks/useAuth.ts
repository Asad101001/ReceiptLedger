import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api, getAuthToken, setAuthToken } from '../api/client';
import { LoginRequest, UserSession } from '../types';

const DEV_MOCK_STORAGE_KEY = 'receiptledger_dev_mock_session';

export const isDevMockSession = (): boolean => {
  if (typeof localStorage === 'undefined') return false;
  return localStorage.getItem(DEV_MOCK_STORAGE_KEY) === 'true';
};

export const setDevMockSession = (active: boolean): void => {
  if (typeof localStorage === 'undefined') return;
  if (active) {
    localStorage.setItem(DEV_MOCK_STORAGE_KEY, 'true');
  } else {
    localStorage.removeItem(DEV_MOCK_STORAGE_KEY);
  }
};

export function useAuth() {
  const queryClient = useQueryClient();
  const token = getAuthToken();
  const isMock = isDevMockSession();

  const sessionQuery = useQuery<UserSession | null>({
    queryKey: ['auth', 'session'],
    queryFn: async () => {
      // 1. Separate offline development mock session check
      if (isDevMockSession()) {
        return {
          user_id: 'usr_dev_mock',
          email: 'user@receiptledger.com',
          full_name: 'Demo Manager (Offline Dev Mode)',
          role: 'admin',
          is_authenticated: false, // Explicitly marked as not genuinely authenticated by backend
          created_at: '2026-01-01T00:00:00Z',
        };
      }

      // 2. Real authentication session check via GET /api/v1/auth/me
      const currentToken = getAuthToken();
      if (!currentToken) return null;

      try {
        return await api.getCurrentUser();
      } catch {
        setAuthToken(null);
        return null;
      }
    },
    staleTime: 5 * 60 * 1000,
    retry: false,
  });

  const loginMutation = useMutation({
    mutationFn: async (credentials: LoginRequest) => {
      setDevMockSession(false); // Clear any mock session on real login attempt
      const res = await api.login(credentials);
      return res.user;
    },
    onSuccess: (user) => {
      setDevMockSession(false);
      queryClient.setQueryData(['auth', 'session'], user);
      queryClient.invalidateQueries();
    },
  });

  const logoutMutation = useMutation({
    mutationFn: async () => {
      if (isDevMockSession()) {
        setDevMockSession(false);
      } else {
        try {
          api.logout();
        } catch {
          // Ignore network errors during client logout
        }
      }
      setAuthToken(null);
    },
    onSuccess: () => {
      setDevMockSession(false);
      queryClient.setQueryData(['auth', 'session'], null);
      queryClient.clear();
    },
  });

  const enterDevMockMode = () => {
    // Safety: ensure real access token storage is NOT used for mock mode
    setAuthToken(null);
    setDevMockSession(true);

    const mockUser: UserSession = {
      user_id: 'usr_dev_mock',
      email: 'user@receiptledger.com',
      full_name: 'Demo Manager (Offline Dev Mode)',
      role: 'admin',
      is_authenticated: false, // Clearly not authenticated by backend
      created_at: '2026-01-01T00:00:00Z',
    };
    queryClient.setQueryData(['auth', 'session'], mockUser);
    queryClient.invalidateQueries();
  };

  const hasRealSession = Boolean(token && sessionQuery.data?.is_authenticated);

  return {
    user: sessionQuery.data,
    isAuthenticated: Boolean(hasRealSession || isMock),
    isMockMode: isMock,
    isLoading: sessionQuery.isLoading,
    login: loginMutation.mutateAsync,
    isLoggingIn: loginMutation.isPending,
    loginError: loginMutation.error,
    logout: logoutMutation.mutate,
    enterDevMockMode,
  };
}
