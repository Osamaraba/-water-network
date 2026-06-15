import { useState, useRef, useCallback } from "react";
import { SimulationStep, SimulationConfig, Subscriber } from "../types";

export const useWebSocket = () => {
  const [steps, setSteps] = useState<SimulationStep[]>([]);
  const [lastStep, setLastStep] = useState<SimulationStep | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [isFinished, setIsFinished] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const currentSimId = useRef<string | null>(null);

  const startSimulation = useCallback((config: SimulationConfig, subscribers: Subscriber[]) => {
    setSteps([]);
    setLastStep(null);
    setIsFinished(false);
    setError(null);

    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }

    const simId = `sim_${Date.now()}`;
    const ws = new WebSocket(`ws://localhost:8002/ws/${simId}`);

    ws.onopen = () => {
      setIsConnected(true);
      setError(null);
      ws.send(JSON.stringify({ config, subscribers }));
    };
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.status === "finished") {
        setIsFinished(true);
      } else if (data.error) {
        setError(data.error);
      } else {
        const step = data as SimulationStep;
        setLastStep(step);
        setSteps(prev => [...prev, step]);
      }
    };
    ws.onerror = () => { setError("WebSocket error"); };
    ws.onclose = () => { setIsConnected(false); };
    wsRef.current = ws;
  }, []);

  const resetSimulation = useCallback(() => {
    setSteps([]);
    setLastStep(null);
    setIsFinished(false);
    setError(null);
    if (wsRef.current) { wsRef.current.close(); wsRef.current = null; }
  }, []);

  const sendCommand = useCallback((command: string, value?: number) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ command, value }));
    }
  }, []);

  return { lastStep, steps, isConnected, isFinished, error, startSimulation, resetSimulation, sendCommand };
};