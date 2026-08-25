import { useState } from 'react'
import { Calendar, Clock, MapPin, CheckCircle, XCircle, AlertTriangle } from 'lucide-react'

const mockAttendance = [
  { id: 1, employee: 'أحمد محمد', date: '2026-08-21', checkIn: '08:00:15', checkOut: '16:05:30', duration: '8س 5د', status: 'valid', trustScore: 95, location: '32.3325, 35.7523' },
  { id: 2, employee: 'خالد عمر', date: '2026-08-21', checkIn: '08:05:22', checkOut: null, duration: '-', status: 'active', trustScore: 88, location: '32.3350, 35.7550' },
  { id: 3, employee: 'محمد سعيد', date: '2026-08-21', checkIn: '07:55:10', checkOut: '14:00:45', duration: '6س 5د', status: 'valid', trustScore: 92, location: '32.3300, 35.7500' },
  { id: 4, employee: 'عمر فؤاد', date: '2026-08-21', checkIn: '08:30:00', checkOut: null, duration: '-', status: 'warning', trustScore: 45, location: '32.3280, 35.7480' },
  { id: 5, employee: 'سامي الرفاعي', date: '2026-08-21', checkIn: '08:02:18', checkOut: '16:00:05', duration: '7س 58د', status: 'valid', trustScore: 98, location: '32.3325, 35.7523' },
]

export default function AttendancePage() {
  const [filter, setFilter] = useState('all')

  const filtered = mockAttendance.filter((a) => {
    if (filter === 'all') return true
    if (filter === 'active') return a.status === 'active'
    if (filter === 'completed') return a.checkOut !== null
    if (filter === 'warning') return a.status === 'warning'
    return true
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">سجلات الحضور</h1>
          <p className="text-gray-500 mt-1">مراقبة وإدارة سجلات الدوام</p>
        </div>
        <button className="bg-primary-700 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-primary-800 transition-colors">
          تصدير التقرير
        </button>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'إجمالي السجلات', value: '24', icon: Calendar, color: 'text-blue-600' },
          { label: 'نشطون الآن', value: '8', icon: Clock, color: 'text-green-600' },
          { label: 'مكتمل', value: '16', icon: CheckCircle, color: 'text-emerald-600' },
          { label: 'مشبوه', value: '2', icon: AlertTriangle, color: 'text-red-600' },
        ].map((stat) => (
          <div key={stat.label} className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <stat.icon className={`w-5 h-5 ${stat.color}`} />
              <div>
                <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                <p className="text-xs text-gray-500">{stat.label}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="flex gap-2">
        {(['all', 'active', 'completed', 'warning'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter === f
                ? 'bg-primary-700 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {f === 'all' ? 'الكل' : f === 'active' ? 'نشط' : f === 'completed' ? 'مكتمل' : 'مشبوه'}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full text-right">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الموظف</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">التاريخ</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الدخول</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الخروج</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">المدة</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الثقة</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الحالة</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map((record) => (
              <tr key={record.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-6 py-4 text-sm font-medium text-gray-900">{record.employee}</td>
                <td className="px-6 py-4 text-sm text-gray-600">{record.date}</td>
                <td className="px-6 py-4 text-sm text-gray-600">{record.checkIn}</td>
                <td className="px-6 py-4 text-sm text-gray-600">{record.checkOut || '-'}</td>
                <td className="px-6 py-4 text-sm text-gray-600">{record.duration}</td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <div className="w-16 h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className={`h-full rounded-full ${
                          record.trustScore >= 80 ? 'bg-green-500' :
                          record.trustScore >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                        }`}
                        style={{ width: `${record.trustScore}%` }}
                      />
                    </div>
                    <span className="text-sm text-gray-600">{record.trustScore}</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${
                    record.status === 'valid' ? 'bg-green-100 text-green-700' :
                    record.status === 'active' ? 'bg-blue-100 text-blue-700' :
                    'bg-red-100 text-red-700'
                  }`}>
                    {record.status === 'valid' ? <CheckCircle className="w-3 h-3" /> :
                     record.status === 'active' ? <Clock className="w-3 h-3" /> :
                     <XCircle className="w-3 h-3" />}
                    {record.status === 'valid' ? 'صالح' : record.status === 'active' ? 'نشط' : 'مشبوه'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
