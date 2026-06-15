import React from "react";
import { Subscriber } from "../types";

const Summary: React.FC<{ subscribers: Subscriber[] }> = ({ subscribers }) => {
  const total = subscribers.length;
  const completed = subscribers.filter(s => s.completed).length;
  const pending = total - completed;
  const totalDemand = subscribers.reduce((s, sub) => s + sub.demand, 0);
  const totalReceived = subscribers.reduce((s, sub) => s + sub.received, 0);
  const avgPercent = totalDemand > 0 ? (totalReceived / totalDemand) * 100 : 0;
  const withArrival = subscribers.filter(s => s.arrival_time !== null);
  const avgArrival = withArrival.length > 0
    ? withArrival.reduce((s, sub) => s + (sub.arrival_time || 0), 0) / withArrival.length
    : 0;

  return (
    <div style={{
      marginTop: 16, padding: 16, border: "2px solid #28a745", borderRadius: 8,
      backgroundColor: "#f0fff4"
    }}>
      <h3>ملخص المحاكاة</h3>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <tbody>
          <tr><td>إجمالي المشتركين</td><td>{total}</td></tr>
          <tr><td>مكتمل</td><td>{completed}</td></tr>
          <tr><td>متبقي</td><td>{pending}</td></tr>
          <tr><td>إجمالي الطلب</td><td>{totalDemand.toFixed(2)} م³</td></tr>
          <tr><td>إجمالي المستلم</td><td>{totalReceived.toFixed(2)} م³</td></tr>
          <tr><td>نسبة الإنجاز</td><td>{avgPercent.toFixed(1)}%</td></tr>
          <tr><td>متوسط زمن الوصول</td><td>{avgArrival.toFixed(2)} ساعة</td></tr>
        </tbody>
      </table>
    </div>
  );
};
export default Summary;