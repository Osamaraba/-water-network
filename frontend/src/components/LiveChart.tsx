import React from "react";
import { LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer } from "recharts";
import { SimulationStep } from "../types";

const LiveChart: React.FC<{ steps: SimulationStep[] }> = ({ steps }) => {
  const data = steps.map(s => ({ time: s.time, level: s.water_level }));
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={data}>
        <XAxis dataKey="time" />
        <YAxis />
        <CartesianGrid strokeDasharray="3 3" />
        <Tooltip />
        <Line type="monotone" dataKey="level" stroke="#1f77b4" dot={false} />
      </LineChart>
    </ResponsiveContainer>
  );
};
export default LiveChart;
