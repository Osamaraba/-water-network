import { useState } from 'react'
import { FileText, Download, Calendar, Users, Clock, TrendingUp } from 'lucide-react'

const reportTypes = [
  { id: 'attendance', name: 'تقرير الحضور والانصراف', icon: Clock, description: 'سجل الدوام اليومي والشهري للموظفين' },
  { id: 'overtime', name: 'تقرير الإضافي', icon: TrendingUp, description: 'ساعات العمل الإضافي والموافقات' },
  { id: 'incidents', name: 'تقرير الحوادث', icon: FileText, description: 'إحصائيات الحوادث والصيانة' },
  { id: 'collectors', name: 'تقرير الجباة', icon: Users, description: 'قراءات العدادات والتحصيل' },
  { id: 'routes', name: 'تقرير المسارات', icon: Calendar, description: 'تحليل مسارات الموظفين الميدانيين' },
  { id: 'security', name: 'تقرير الأمان', icon: FileText, description: 'الأحداث الأمنية والمخالفات' },
]

export default function ReportsPage() {
  const [selectedReport, setSelectedReport] = useState<string | null>(null)
  const [dateRange, setDateRange] = useState('month')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">التقارير</h1>
          <p className="text-gray-500 mt-1">إنشاء وتصدير التقارير الإحصائية</p>
        </div>
      </div>

      <div className="flex gap-2">
        {(['today', 'week', 'month', 'quarter', 'year'] as const).map((range) => (
          <button
            key={range}
            onClick={() => setDateRange(range)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              dateRange === range
                ? 'bg-primary-700 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {range === 'today' ? 'اليوم' : range === 'week' ? 'الأسبوع' : range === 'month' ? 'الشهر' : range === 'quarter' ? 'الربع' : 'السنة'}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {reportTypes.map((report) => {
          const Icon = report.icon
          return (
            <div
              key={report.id}
              onClick={() => setSelectedReport(report.id)}
              className={`bg-white rounded-xl border p-6 cursor-pointer transition-all hover:shadow-md ${
                selectedReport === report.id
                  ? 'border-primary-500 ring-2 ring-primary-100'
                  : 'border-gray-200'
              }`}
            >
              <div className="flex items-start justify-between mb-4">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                  selectedReport === report.id ? 'bg-primary-100' : 'bg-gray-100'
                }`}>
                  <Icon className={`w-6 h-6 ${
                    selectedReport === report.id ? 'text-primary-700' : 'text-gray-500'
                  }`} />
                </div>
                <button className="p-2 text-gray-400 hover:text-primary-600 transition-colors">
                  <Download className="w-4 h-4" />
                </button>
              </div>
              <h3 className="font-semibold text-gray-900 mb-1">{report.name}</h3>
              <p className="text-sm text-gray-500">{report.description}</p>
            </div>
          )
        })}
      </div>

      {selectedReport && (
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-gray-900">
              معاينة: {reportTypes.find(r => r.id === selectedReport)?.name}
            </h3>
            <div className="flex gap-2">
              <button className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 transition-colors">
                <Download className="w-4 h-4" />
                Excel
              </button>
              <button className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 transition-colors">
                <Download className="w-4 h-4" />
                PDF
              </button>
              <button className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg text-sm font-medium hover:bg-gray-700 transition-colors">
                <Download className="w-4 h-4" />
                CSV
              </button>
            </div>
          </div>

          <div className="border rounded-lg overflow-hidden">
            <table className="w-full text-right">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-xs font-medium text-gray-500">#</th>
                  <th className="px-4 py-3 text-xs font-medium text-gray-500">التاريخ</th>
                  <th className="px-4 py-3 text-xs font-medium text-gray-500">القيمة</th>
                  <th className="px-4 py-3 text-xs font-medium text-gray-500">التغيير</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {[1, 2, 3, 4, 5].map((i) => (
                  <tr key={i}>
                    <td className="px-4 py-3 text-sm text-gray-600">{i}</td>
                    <td className="px-4 py-3 text-sm text-gray-900">2026-08-{20 + i}</td>
                    <td className="px-4 py-3 text-sm text-gray-900">{Math.floor(Math.random() * 100)}</td>
                    <td className="px-4 py-3 text-sm text-green-600">+{Math.floor(Math.random() * 20)}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
