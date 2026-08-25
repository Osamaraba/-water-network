import { NavLink, useLocation } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  Map,
  ClipboardCheck,
  AlertTriangle,
  FileBarChart,
  Settings,
  Droplets,
} from 'lucide-react'

const menuItems = [
  { path: '/', label: 'لوحة التحكم', icon: LayoutDashboard },
  { path: '/employees', label: 'الموظفين', icon: Users },
  { path: '/map', label: 'الخريطة المباشرة', icon: Map },
  { path: '/attendance', label: 'سجلات الحضور', icon: ClipboardCheck },
  { path: '/incidents', label: 'الحوادث', icon: AlertTriangle },
  { path: '/reports', label: 'التقارير', icon: FileBarChart },
]

export default function Sidebar() {
  const location = useLocation()

  return (
    <aside className="w-64 bg-white border-l border-gray-200 flex flex-col">
      <div className="p-6 border-b border-gray-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primary-700 rounded-xl flex items-center justify-center">
            <Droplets className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="font-bold text-gray-900 text-sm">مياه اليرموك</h1>
            <p className="text-xs text-gray-500">لوحة التحكم</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {menuItems.map((item) => {
          const Icon = item.icon
          const isActive = location.pathname === item.path
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary-50 text-primary-700'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`}
            >
              <Icon className="w-5 h-5" />
              {item.label}
            </NavLink>
          )
        })}
      </nav>

      <div className="p-4 border-t border-gray-100">
        <button className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-sm text-gray-600 hover:bg-gray-50 transition-colors">
          <Settings className="w-5 h-5" />
          الإعدادات
        </button>
      </div>
    </aside>
  )
}
