import { useState } from 'react'
import { Droplets } from 'lucide-react'
import { useAuthStore } from '../hooks/useAuth'

export default function Login() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const { setAuth } = useAuthStore()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError('')

    try {
      // Demo login - in production, call API
      if (username && password) {
        setAuth(
          'demo-token',
          'demo-refresh',
          {
            employee_id: 1,
            full_name: 'أحمد محمد الخالدي',
            employee_number: username,
            department: 'الصيانة',
            role: 'maintenance_tech',
          }
        )
      } else {
        setError('يرجى إدخال اسم المستخدم وكلمة المرور')
      }
    } catch {
      setError('خطأ في تسجيل الدخول')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-800 to-primary-900 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-primary-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Droplets className="w-8 h-8 text-primary-700" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">شركة مياه اليرموك</h1>
          <p className="text-gray-500 mt-2">نظام إدارة الدوام والمواقع</p>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">اسم المستخدم</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500 text-right"
              placeholder="أدخل اسم المستخدم"
              dir="rtl"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">كلمة المرور</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500 text-right"
              placeholder="أدخل كلمة المرور"
              dir="rtl"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-primary-700 text-white py-3 rounded-xl font-medium hover:bg-primary-800 transition-colors disabled:opacity-50"
          >
            {isLoading ? 'جاري الدخول...' : 'تسجيل الدخول'}
          </button>
        </form>

        <div className="mt-6 text-center text-sm text-gray-500">
          <p>الجهاز: f8a2...b4c1 ✓</p>
        </div>
      </div>
    </div>
  )
}
