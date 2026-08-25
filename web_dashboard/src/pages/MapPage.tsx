import { useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup, Circle, Polygon } from 'react-leaflet'
import { LatLngExpression } from 'leaflet'
import { Layers, Navigation, Users, Filter } from 'lucide-react'
import 'leaflet/dist/leaflet.css'

const center: LatLngExpression = [32.3325, 35.7523]

const employees = [
  { id: 1, name: 'أحمد محمد', lat: 32.333, lng: 35.753, status: 'active', role: 'فني صيانة', speed: 12, battery: 78 },
  { id: 2, name: 'خالد عمر', lat: 32.335, lng: 35.755, status: 'active', role: 'فني صيانة', speed: 0, battery: 45 },
  { id: 3, name: 'محمد سعيد', lat: 32.330, lng: 35.750, status: 'warning', role: 'جابي', speed: 8, battery: 92 },
  { id: 4, name: 'عمر فؤاد', lat: 32.328, lng: 35.748, status: 'danger', role: 'موزع مياه', speed: 0, battery: 23 },
]

const zones = [
  { id: 1, name: 'منطقة الصيانة', points: [[32.334, 35.751], [32.336, 35.754], [32.332, 35.756], [32.330, 35.753]] as LatLngExpression[] },
]

export default function MapPage() {
  const [selectedLayer, setSelectedLayer] = useState('employees')

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">الخريطة المباشرة</h1>
          <p className="text-gray-500 mt-1">تتبع المواقع والمناطق في الوقت الفعلي</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setSelectedLayer('employees')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              selectedLayer === 'employees' ? 'bg-primary-700 text-white' : 'bg-white text-gray-600 border border-gray-200'
            }`}
          >
            <Users className="w-4 h-4" />
            الموظفون
          </button>
          <button
            onClick={() => setSelectedLayer('zones')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              selectedLayer === 'zones' ? 'bg-primary-700 text-white' : 'bg-white text-gray-600 border border-gray-200'
            }`}
          >
            <Layers className="w-4 h-4" />
            المناطق
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <div className="lg:col-span-3">
          <div className="bg-white rounded-xl border border-gray-200 overflow-hidden" style={{ height: '600px' }}>
            <MapContainer center={center} zoom={14} style={{ height: '100%', width: '100%' }}>
              <TileLayer
                attribution='&copy; OpenStreetMap'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />

              {selectedLayer === 'zones' && zones.map((zone) => (
                <Polygon
                  key={zone.id}
                  positions={zone.points}
                  pathOptions={{ fillColor: '#3b82f6', fillOpacity: 0.1, color: '#3b82f6', weight: 2 }}
                >
                  <Popup>{zone.name}</Popup>
                </Polygon>
              ))}

              {employees.map((emp) => (
                <Marker key={emp.id} position={[emp.lat, emp.lng]}>
                  <Popup>
                    <div className="text-right min-w-[200px]">
                      <p className="font-bold text-lg">{emp.name}</p>
                      <p className="text-sm text-gray-600">{emp.role}</p>
                      <div className="mt-2 space-y-1 text-sm">
                        <p>السرعة: {emp.speed} كم/س</p>
                        <p>البطارية: {emp.battery}%</p>
                      </div>
                      <span className={`inline-block px-2 py-0.5 rounded text-xs mt-2 ${
                        emp.status === 'active' ? 'bg-green-100 text-green-700' :
                        emp.status === 'warning' ? 'bg-yellow-100 text-yellow-700' :
                        'bg-red-100 text-red-700'
                      }`}>
                        {emp.status === 'active' ? 'نشط' : emp.status === 'warning' ? 'بين المهام' : 'خارج المنطقة'}
                      </span>
                    </div>
                  </Popup>
                  <Circle
                    center={[emp.lat, emp.lng]}
                    radius={50}
                    pathOptions={{
                      fillColor: emp.status === 'active' ? '#22c55e' : emp.status === 'warning' ? '#eab308' : '#ef4444',
                      fillOpacity: 0.1,
                      color: emp.status === 'active' ? '#22c55e' : emp.status === 'warning' ? '#eab308' : '#ef4444',
                      weight: 1,
                    }}
                  />
                </Marker>
              ))}
            </MapContainer>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <h3 className="font-semibold text-gray-900 mb-3">الموظفون النشطون</h3>
            <div className="space-y-3">
              {employees.map((emp) => (
                <div key={emp.id} className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded-lg cursor-pointer transition-colors">
                  <div className={`w-3 h-3 rounded-full ${
                    emp.status === 'active' ? 'bg-green-500' :
                    emp.status === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
                  }`} />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-gray-900">{emp.name}</p>
                    <p className="text-xs text-gray-500">{emp.role}</p>
                  </div>
                  <div className="text-xs text-gray-400">
                    {emp.speed > 0 ? `${emp.speed} كم/س` : 'ثابت'}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <h3 className="font-semibold text-gray-900 mb-3">أدوات</h3>
            <div className="space-y-2">
              <button className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-600 hover:bg-gray-50 rounded-lg transition-colors">
                <Navigation className="w-4 h-4" />
                تحديد موقع
              </button>
              <button className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-600 hover:bg-gray-50 rounded-lg transition-colors">
                <Filter className="w-4 h-4" />
                تصفية
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
