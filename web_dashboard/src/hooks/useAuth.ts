import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  token: string | null
  refreshToken: string | null
  employee: any | null
  isAuthenticated: boolean
  setAuth: (token: string, refreshToken: string, employee: any) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      refreshToken: null,
      employee: null,
      isAuthenticated: false,
      setAuth: (token, refreshToken, employee) =>
        set({ token, refreshToken, employee, isAuthenticated: true }),
      logout: () =>
        set({ token: null, refreshToken: null, employee: null, isAuthenticated: false }),
    }),
    { name: 'yarmouk-auth' }
  )
)
