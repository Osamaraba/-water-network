import { useState } from 'react'
import { AlertTriangle, Clock, MapPin, CheckCircle, ChevronRight } from 'lucide-react'

const mockIncidents = [
  { id: 1, number: 'INC-20260821-A1B2', title: 'كسر في خط مياه رئيسي', type: 'صيانة', priority: 'critical', status: 'in_progress', location: 'شارع الملك حسين', assigned: 'أحمد محمد', created: '08:30', updated: '10:15' },
  { id: 2, number: 'INC-20260821-C3D4', title: 'تسرب مياه في منزل', type: 'صيانة', priority: 'high', status: 'arrived', location: 'حي النزهة', assigned: 'خالد عمر', created: '09:00', updated: '09:45' },
  { id: 3, number: 'INC-20260821-E5F6', title: 'عداد تالف', type: 'جباية', priority: 'medium', status: 'assigned', location: 'شارع الجامعة', assigned: 'محمد سعيد', created: '09:30', updated: '09:30' },
  { id: 4, number: 'INC-20260821-G7H8', title: 'انقطاع مياه', type: 'توزيع', priority: 'high', status: 'new', location: 'منطقة الصناعة', assigned: '-', created: '10:00', updated: '10:00' },
  { id: 5, number: 'INC-20260821-I9J0', title: 'صيانة دورية', type: 'صيانة', priority: 'low', status: 'completed', location: 'مقر الإدارة', assigned: 'أحمد محمد', created: '07:00', updated: '08:30' },
]

const priorityColors: Record<string, string> = {
  critical: 'bg-red-100 text-red-700 border-red-200',
  high: 'bg-orange-100 text-orange-700 border-orange-200',
  medium: 'bg-yellow-100 text-yellow-700 border-yellow-200',
  low: 'bg-green-100 text-green-700 border-green-200',
}

const statusColors: Record<string, string> = {
  new: 'bg-gray-100 text-gray-700',
  assigned: 'bg-blue-100 text-blue-700',
  accepted: 'bg-indigo-100 text-indigo-700',
  arrived: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-orange-100 text-orange-700',
  completed: 'bg-green-100 text-green-700',
  closed: 'bg-gray-100 text-gray-500',
}

const statusLabels: Record<string, string> = {
  new: 'جديد',
  assigned: 'معين',
  accepted: 'مقبول',
  arrived: 'تم الوصول',
  in_progress: 'قيد الإصلاح',
  completed: 'مكتمل',
  closed: 'مغلق',
}

export default function IncidentsPage() {
  const [filter, setFilter] = useState('all')

  const filtered = mockIncidents.filter((i) => {
    if (filter === 'all') return true
    if (filter === 'open') return !['completed', 'closed'].includes(i.status)
    if (filter === 'critical') return i.priority === 'critical'
    return true
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">الحوادث</h1>
          <p className="text-gray-500 mt-1">إدارة وتتبع حوادث الشبكة والصيانة</p>
        </div>
        <button className="bg-primary-700 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-primary-800 transition-colors">
          + إنشاء حادث
        </button>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'إجمالي الحوادث', value: '7', color: 'bg-blue-500' },
          { label: 'مفتوحة', value: '4', color: 'bg-orange-500' },
          { label: 'حرجة', value: '1', color: 'bg-red-500' },
          { label: 'مكتملة', value: '2', color: 'bg-green-500' },
        ].map((stat) => (
          <div key={stat.label} className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 ${stat.color} rounded-xl flex items-center justify-center`}>
                <AlertTriangle className="w-5 h-5 text-white" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                <p className="text-xs text-gray-500">{stat.label}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="flex gap-2">
        {(['all', 'open', 'critical'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              filter === f
                ? 'bg-primary-700 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {f === 'all' ? 'الكل' : f === 'open' ? 'مفتوحة' : 'حرجة'}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full text-right">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الحادث</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الأولوية</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الحالة</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الموقع</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">المعين</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الوقت</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map((incident) => (
              <tr key={incident.id} className="hover:bg-gray-50 transition-colors cursor-pointer">
                <td className="px-6 py-4">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{incident.title}</p>
                    <p className="text-xs text-gray-500">{incident.number}</p>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium border ${priorityColors[incident.priority]}`}>
                    {incident.priority === 'critical' ? 'حرج' : incident.priority === 'high' ? 'عالي' : incident.priority === 'medium' ? 'متوسط' : 'منخفض'}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium ${statusColors[incident.status]}`}>
                    {statusLabels[incident.status]}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-1 text-sm text-gray-600">
                    <MapPin className="w-3.5 h-3.5" />
                    {incident.location}
                  </div>
                </td>
                <td className="px-6 py-4 text-sm text-gray-600">{incident.assigned}</td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-1 text-sm text-gray-500">
                    <Clock className="w-3.5 h-3.5" />
                    {incident.created}
                  </div>
                </td>
                <td className="px-6 py-4">
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
