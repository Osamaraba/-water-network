import { useState } from 'react'
import { Search, Filter, MoreVertical, Phone, Mail, MapPin } from 'lucide-react'

const mockEmployees = [
  { id: 1, name: 'أحمد محمد الخالدي', number: 'EMP001', role: 'فني صيانة', department: 'الصيانة', branch: 'عجلون', status: 'active', phone: '0791234567' },
  { id: 2, name: 'خالد عمر العبادي', number: 'EMP002', role: 'فني صيانة', department: 'الصيانة', branch: 'عجلون', status: 'active', phone: '0792345678' },
  { id: 3, name: 'محمد سعيد النعيمي', number: 'EMP003', role: 'جابي', department: 'الجباية', branch: 'عجلون', status: 'active', phone: '0793456789' },
  { id: 4, name: 'عمر فؤاد الحسيني', number: 'EMP004', role: 'موزع مياه', department: 'التوزيع', branch: 'عجلون', status: 'active', phone: '0794567890' },
  { id: 5, name: 'سامي رami الرفاعي', number: 'EMP005', role: 'موظف مكتبي', department: 'المكتب', branch: 'عجلون', status: 'active', phone: '0795678901' },
  { id: 6, name: 'ليلى أحمد العمري', number: 'EMP006', role: 'مدير الموارد البشرية', department: 'الموارد البشرية', branch: 'عجلون', status: 'active', phone: '0796789012' },
  { id: 7, name: 'يوسف خالد القحطاني', number: 'EMP007', role: 'مدير الفرع', department: 'الإدارة', branch: 'عجلون', status: 'active', phone: '0797890123' },
  { id: 8, name: 'فاطمة علي الزيود', number: 'EMP008', role: 'مهندس GIS', department: 'GIS', branch: 'عجلون', status: 'active', phone: '0798901234' },
]

const roleColors: Record<string, string> = {
  'فني صيانة': 'bg-orange-100 text-orange-700',
  'جابي': 'bg-pink-100 text-pink-700',
  'موزع مياه': 'bg-cyan-100 text-cyan-700',
  'موظف مكتبي': 'bg-gray-100 text-gray-700',
  'مدير الموارد البشرية': 'bg-red-100 text-red-700',
  'مدير الفرع': 'bg-blue-100 text-blue-700',
  'مهندس GIS': 'bg-green-100 text-green-700',
}

export default function Employees() {
  const [search, setSearch] = useState('')
  const [filterRole, setFilterRole] = useState('all')

  const filtered = mockEmployees.filter((emp) => {
    const matchesSearch = emp.name.includes(search) || emp.number.includes(search)
    const matchesRole = filterRole === 'all' || emp.role === filterRole
    return matchesSearch && matchesRole
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">الموظفين</h1>
          <p className="text-gray-500 mt-1">إدارة ومراقبة الموظفين</p>
        </div>
        <button className="bg-primary-700 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-primary-800 transition-colors">
          + إضافة موظف
        </button>
      </div>

      <div className="flex gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="بحث بالاسم أو الرقم..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pr-10 pl-4 py-2 bg-white border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 text-right"
            dir="rtl"
          />
        </div>
        <select
          value={filterRole}
          onChange={(e) => setFilterRole(e.target.value)}
          className="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        >
          <option value="all">جميع الأدوار</option>
          <option value="فني صيانة">فني صيانة</option>
          <option value="جابي">جابي</option>
          <option value="موزع مياه">موزع مياه</option>
          <option value="موظف مكتبي">موظف مكتبي</option>
        </select>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full text-right">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الموظف</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الدور</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">القسم</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الفرع</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الحالة</th>
              <th className="px-6 py-3 text-xs font-medium text-gray-500">الإجراءات</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map((emp) => (
              <tr key={emp.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                      <span className="text-sm font-bold text-primary-700">
                        {emp.name.split(' ').map((n) => n[0]).slice(0, 2).join('')}
                      </span>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{emp.name}</p>
                      <p className="text-xs text-gray-500">{emp.number}</p>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium ${roleColors[emp.role] || 'bg-gray-100 text-gray-700'}`}>
                    {emp.role}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-600">{emp.department}</td>
                <td className="px-6 py-4 text-sm text-gray-600">{emp.branch}</td>
                <td className="px-6 py-4">
                  <span className="inline-flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-green-500" />
                    <span className="text-sm text-gray-600">نشط</span>
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <button className="p-1.5 text-gray-400 hover:text-primary-600 transition-colors" title="اتصال">
                      <Phone className="w-4 h-4" />
                    </button>
                    <button className="p-1.5 text-gray-400 hover:text-primary-600 transition-colors" title="بريد">
                      <Mail className="w-4 h-4" />
                    </button>
                    <button className="p-1.5 text-gray-400 hover:text-primary-600 transition-colors" title="موقع">
                      <MapPin className="w-4 h-4" />
                    </button>
                    <button className="p-1.5 text-gray-400 hover:text-gray-600 transition-colors">
                      <MoreVertical className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
