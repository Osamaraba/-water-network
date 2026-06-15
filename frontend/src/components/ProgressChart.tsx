import React from "react";
import { LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer, Legend } from "recharts";
import { SimulationStep } from "../types";

const ProgressChart: React.FC<{ steps: SimulationStep[] }> = ({ steps }) => {
  const data = steps.map((step) => {
    let completed = 0, filling = 0, waiting = 0;
    for (const s of step.subscribers) {
      if (s.completed) completed += s.received;
      else if (s.arrival_time !== null) filling += s.received;
      else waiting += s.received;
    }
    return { time: step.time, مكتمل: Math.round(completed), يُعبأ: Math.round(filling), انتظار: Math.round(waiting) };
  });

  return (
    <div style={{ marginTop: 16 }}>
      <h4>تقدم المشتركين</h4>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <XAxis dataKey="time" label={{ value: "الزمن (ساعة)", position: "bottom" }} />
          <YAxis label={{ value: "المياه المستلمة (م³)", angle: -90, position: "insideLeft" }} />
          <CartesianGrid strokeDasharray="3 3" />
          <Tooltip />
          <Legend />
          <Line type="monotone" dataKey="مكتمل" stroke="#1f77b4" dot={false} strokeWidth={2} />
          <Line type="monotone" dataKey="يُعبأ" stroke="#e91e9e" dot={false} strokeWidth={2} />
          <Line type="monotone" dataKey="انتظار" stroke="#d32f2f" dot={false} strokeWidth={2} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};
export default ProgressChart;