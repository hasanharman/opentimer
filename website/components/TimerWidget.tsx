"use client";

import { useEffect, useState } from "react";
import { Play, Pause, ChevronsUpDown, SquareArrowOutUpRight } from "lucide-react";

function format(total: number) {
  const h = Math.floor(total / 3600)
    .toString()
    .padStart(2, "0");
  const m = Math.floor((total % 3600) / 60)
    .toString()
    .padStart(2, "0");
  const s = Math.floor(total % 60)
    .toString()
    .padStart(2, "0");
  return `${h}:${m}:${s}`;
}

const weekBars = [70, 42, 96, 30, 58, 18, 8];
const recent = [
  { name: "JFK", color: "#0a84ff", time: "2h 14m" },
  { name: "Acme Redesign", color: "#34c759", time: "1h 02m" },
  { name: "Freelance Timer", color: "#30d158", time: "0h 46m" },
];

/**
 * A faithful, *live* recreation of the app's menu bar popover.
 * The timer actually runs when "playing" so the hero feels alive.
 */
export function TimerWidget({
  onOpenApp,
  onClose,
}: {
  onOpenApp?: () => void;
  onClose?: () => void;
}) {
  const [seconds, setSeconds] = useState(0);
  const [running, setRunning] = useState(true);

  // Begin from a believable in-progress session the moment the visitor lands,
  // then keep ticking — as if they're already tracking real work.
  useEffect(() => {
    setSeconds(Math.floor(Math.random() * 9000) + 1500); // ~25min – 2.9h
  }, []);

  useEffect(() => {
    if (!running) return;
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id);
  }, [running]);

  return (
    <div className="w-[300px] select-none rounded-[20px] border border-white/10 bg-[#0b1830] p-4 text-white shadow-[0_30px_80px_-20px_rgba(4,12,35,0.95)] ring-1 ring-black/50">
      {/* header */}
      <div className="mb-4 flex items-center justify-between">
        <span className="text-[13px] font-semibold tracking-tight">
          Freelance Timer
        </span>
        <button
          onClick={onClose}
          aria-label="Close"
          className="grid h-5 w-5 place-items-center rounded-full bg-white/10 text-[12px] text-white/70 transition hover:bg-white/20 hover:text-white"
        >
          ×
        </button>
      </div>

      {/* project picker */}
      <label className="mb-1.5 block text-[11px] font-medium text-white/45">
        Project
      </label>
      <button className="mb-4 flex w-full items-center justify-between rounded-lg bg-white/[0.07] px-3 py-2 text-[12px] font-medium ring-1 ring-white/10">
        <span>Github · Freelance Timer</span>
        <ChevronsUpDown className="h-3.5 w-3.5 text-white/45" />
      </button>

      {/* timer */}
      <p className="mb-1 text-[11px] text-white/40">
        {running ? "Tracking…" : "Ready to start"}
      </p>
      <div className="mb-5 flex items-center justify-between">
        <span className="tabular text-[34px] font-semibold leading-none tracking-tight">
          {format(seconds)}
        </span>
        <button
          onClick={() => setRunning((r) => !r)}
          aria-label={running ? "Pause timer" : "Start timer"}
          className="grid h-11 w-11 place-items-center rounded-full bg-accent text-white shadow-lg shadow-accent/30 transition active:scale-95"
        >
          {running ? (
            <Pause className="h-5 w-5 fill-current" />
          ) : (
            <Play className="ml-0.5 h-5 w-5 fill-current" />
          )}
        </button>
      </div>

      {/* this week */}
      <div className="mb-4">
        <div className="mb-2 flex items-center justify-between">
          <span className="text-[12px] font-medium text-white/70">
            This week
          </span>
          <span className="text-[12px] text-white/45">5h 45m</span>
        </div>
        <div className="flex h-12 items-end gap-1.5">
          {weekBars.map((h, i) => (
            <div
              key={i}
              className="flex-1 rounded-[3px] bg-accent"
              style={{ height: `${h}%`, opacity: i === 2 ? 1 : 0.55 }}
            />
          ))}
        </div>
      </div>

      {/* recent */}
      <span className="mb-2 block text-[12px] font-medium text-white/70">
        Recent
      </span>
      <ul className="space-y-2">
        {recent.map((r) => (
          <li key={r.name} className="flex items-center justify-between">
            <span className="flex items-center gap-2 text-[12px] text-white/80">
              <span
                className="h-2 w-2 rounded-full"
                style={{ background: r.color }}
              />
              {r.name}
            </span>
            <span className="tabular text-[12px] text-white/45">{r.time}</span>
          </li>
        ))}
      </ul>

      {/* open the real app */}
      <button
        onClick={onOpenApp}
        className="mt-4 flex w-full items-center justify-center gap-1.5 rounded-lg bg-white/[0.07] py-2 text-[12px] font-medium text-white/80 ring-1 ring-white/10 transition hover:bg-white/[0.12] hover:text-white"
      >
        Open app
        <SquareArrowOutUpRight className="h-3 w-3" />
      </button>
    </div>
  );
}
