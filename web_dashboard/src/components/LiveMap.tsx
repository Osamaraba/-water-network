import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet'
import { LatLngExpression } from 'leaflet'
import 'leaflet/dist/leaflet.css'

const center: LatLngExpression = [32.3325, 35.7523]

const employees = [
  { id: 1, name: 'أحمد محمد', lat: 32.333, lng: 35.753, status: 'active', role: 'فني صيانة' },
  { id: 2, name: 'خالد عمر', lat: 32.335, lng: 35.755, status: 'active', role: 'فني صيانة' },
  { id: 3, name: 'محمد سعيد', lat: 32.330, lng: 35.750, status: 'warning', role: 'جابي' },
  { id: 4, name: 'عمر فؤاد', lat: 32.328, lng: 35.748, status: 'danger', role: 'موزع مياه' },
]

export default function LiveMap() {
  return (
    <MapContainer
      center={center}
      zoom={14}
      style={{ height: '100%', width: '100%' }}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />

      {employees.map((emp) => (
        <Marker key={emp.id} position={[emp.lat, emp.lng]}>
          <Popup>
            <div className="text-right">
              <p className="font-bold">{emp.name}</p>
              <p className="text-sm text-gray-600">{emp.role}</p>
              <span className={`inline-block px-2 py-0.5 rounded text-xs mt-1 ${
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
  )
}
