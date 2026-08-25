import { useState } from 'react'
import { Users, MapPin, AlertTriangle, Clock, TrendingUp, Activity } from 'lucide-react'
import StatCard from '../components/StatCard'
import LiveMap from '../components/LiveMap'

const stats = [
  { label: 'الموظفين', value: '24', icon: Users, color: 'bg-blue-500', trend: '+2' },
  { label: 'نشطين الآن', value: '18', icon: Activity, color: 'bg-green-500', trend: '+5' },
  { label: 'خارج المنطقة', value: '3', icon: MapPin, color: 'bg-yellow-500', trend: '-1' },
  { label: 'حوادث مفتوحة', value: '7', icon: AlertTriangle, color: 'bg-red-500', trend: '+2' },
  { label: 'ساعات العمل', value: '156', icon: Clock, color: 'bg-purple-500', trend: '+12' },
  { label: 'الإنتاجية', value: '94%', icon: TrendingUp, color: 'bg-cyan-500', trend: '+3%' },
]

export default function Dashboard() {
  const [timeRange, setTimeRange] = useState('today')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">لوحة التحكم</h1>
          <p className="text-gray-500 mt-1">نظرة عامة على العمليات الميدانية</p>
        </div>
        <div className="flex gap-2">
          {(['today', 'week', 'month'] as const).map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                timeRange === range
                  ? 'bg-primary-700 text-white'
                  : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
              }`}
            >
              {range === 'today' ? 'اليوم' : range === 'week' ? 'الأسبوع' : 'الشهر'}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {stats.map((stat) => (
          <StatCard key={stat.label} {...stat} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">الخريطة المباشرة</h2>
              <div className="flex gap-4 text-sm">
                <span className="flex items-center gap-1">
                  <span className="w-2.5 h-2.5 rounded-full bg-green-500" />
                  نشط
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-2.5 h-2.5 rounded-full bg-yellow-500" />
                  بين المهام
                </span>
                <span className="flex items-center gap-1">
                  <span className="w-2.5 h-2.5 rounded-full bg-red-500" />
                  خارج المنطقة
                </span>
              </div>
            </div>
            <div className="h-96 rounded-lg overflow-hidden">
              <LiveMap />
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">التنبيهات الأخيرة</h2>
            <div className="space-y-3">
              {[
                { type: 'danger', message: 'موقع مزيف مكتشف - الموظف: عمر', time: '10:45 ص' },
                { type: 'warning', message: '3 موظفين خارج المنطقة المصرح بها', time: '09:15 ص' },
                { type: 'success', message: 'تمت مزامنة 42 سجل بنجاح', time: '08:30 ص' },
                { type: 'info', message: 'فني صيانة وصل موقع الحادث #1234', time: '08:15 ص' },
              ].map((alert, i) => (
                <div key={i} className={`p-3 rounded-lg ${
                  alert.type === 'danger' ? 'bg-red-50 border border-red-100' :
                  alert.type === 'warning' ? 'bg-yellow-50 border border-yellow-100' :
                  alert.type === 'success' ? 'bg-green-50 border border-green-100' :
                  'bg-blue-50 border border-blue-100'
                }`}>
                  <p className={`text-sm font-medium ${
                    alert.type === 'danger' ? 'text-red-700' :
                    alert.type === 'warning' ? 'text-yellow-700' :
                    alert.type === 'success' ? 'text-green-700' :
                    'text-blue-700'
                  }`}>{alert.message}</p>
                  <p className="text-xs text-gray-500 mt-1">{alert.time}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">الموظفون النشطون</h2>
            <div className="space-y-3">
              {[
                { name: 'أحمد محمد', role: 'فني صيانة', status: 'active', location: 'شارع الملك' },
                { name: 'خالد عمر', role: 'فني صيانة', status: 'active', location: 'حي النزهة' },
                { name: 'محمد سعيد', role: 'جابي', status: 'warning', location: 'في الطريق' },
              ].map((emp, i) => (
                <div key={i} className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded-lg transition-colors">
                  <div className={`w-2.5 h-2.5 rounded-full ${
                    emp.status === 'active' ? 'bg-green-500' : 'bg-yellow-500'
                  }`} />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-gray-900">{emp.name}</p>
                    <p className="text-xs text-gray-500">{emp.role} • {emp.location}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
