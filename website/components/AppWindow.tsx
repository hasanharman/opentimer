import {
  LayoutGrid,
  Activity,
  Folder,
  Settings,
  Plus,
  PanelLeft,
  Calendar,
  Check,
  Archive,
  Trash2,
  X,
} from "lucide-react";

const chart = [62, 30, 16, 24, 14, 40, 10];
const xLabels = ["30", "31", "1", "2", "3", "4", "5"];

const nav = [
  { label: "Dashboard", icon: LayoutGrid, active: true },
  { label: "Activities", icon: Activity, active: false },
  { label: "Projects", icon: Folder, active: false },
];

const activities = [
  { name: "Freelance Timer", company: "Github", color: "#30d158" },
  { name: "JFK", company: "Grit", color: "#0a84ff" },
  { name: "BA", company: "Up", color: "#ff453a" },
];

/** A faithful recreation of the app's main window — the desktop centerpiece. */
export function AppWindow({
  onClose,
  dragHandleProps,
}: {
  onClose?: () => void;
  dragHandleProps?: React.HTMLAttributes<HTMLDivElement>;
}) {
  return (
    <div className="w-[660px] overflow-hidden rounded-[14px] border border-white/10 bg-[#1b1e25] text-white shadow-[0_40px_100px_-25px_rgba(3,8,25,0.85)] ring-1 ring-black/40">
      {/* title bar (drag handle) */}
      <div
        {...dragHandleProps}
        className="flex cursor-grab touch-none select-none items-center gap-3 border-b border-white/[0.06] px-4 py-2.5 active:cursor-grabbing"
      >
        <div className="group flex gap-1.5">
          <button
            onPointerDown={(e) => e.stopPropagation()}
            onClick={onClose}
            aria-label="Close window"
            className="grid h-3 w-3 place-items-center rounded-full bg-[#ff5f57]"
          >
            <X className="h-2 w-2 text-black/55 opacity-0 transition group-hover:opacity-100" />
          </button>
          <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
          <span className="h-3 w-3 rounded-full bg-[#28c840]" />
        </div>
        <PanelLeft className="ml-1 h-3.5 w-3.5 text-white/40" />
        <span className="text-[12px] font-semibold tracking-tight">
          Freelance Timer
        </span>
      </div>

      <div className="flex">
        {/* sidebar */}
        <div className="flex w-[132px] flex-col justify-between bg-gradient-to-b from-[#15171d] to-[#0f1116] p-2.5">
          <div className="space-y-1">
            {nav.map(({ label, icon: Icon, active }) => (
              <div
                key={label}
                className={`flex items-center gap-2 rounded-md px-2 py-1.5 text-[11px] font-medium ${
                  active ? "bg-[#0a84ff] text-white" : "text-white/60"
                }`}
              >
                <Icon className="h-3.5 w-3.5" />
                {label}
              </div>
            ))}
          </div>
          <div className="flex items-center gap-2 px-2 py-1.5 text-[11px] font-medium text-white/55">
            <Settings className="h-3.5 w-3.5" />
            Settings
          </div>
        </div>

        {/* content */}
        <div className="flex-1 p-3.5">
          {/* header */}
          <div className="mb-3 flex items-center justify-between">
            <span className="text-[13px] font-semibold">Activity Monitor</span>
            <div className="flex items-center gap-1.5 text-[10px]">
              <span className="flex items-center gap-1 rounded-md border border-white/10 px-2 py-1 text-white/70">
                <Plus className="h-3 w-3" /> Add Session
              </span>
              <span className="rounded-md bg-[#0a84ff] px-2 py-1 font-semibold">
                New Project
              </span>
            </div>
          </div>

          {/* tabs + earnings */}
          <div className="mb-3 flex items-center justify-between">
            <div className="flex items-center gap-1 text-[10px]">
              {["Day", "Week", "Month", "Year"].map((t) => (
                <span
                  key={t}
                  className={`rounded-md px-2 py-1 ${
                    t === "Week"
                      ? "bg-[#0a84ff] font-semibold text-white"
                      : "text-white/55"
                  }`}
                >
                  {t}
                </span>
              ))}
              <span className="ml-1 flex items-center gap-1 rounded-md border border-white/10 px-2 py-1 text-white/60">
                <Calendar className="h-3 w-3" /> 30 Mar – 5 Apr
              </span>
            </div>
            <div className="flex items-center gap-1.5 text-[10px] text-white/60">
              Earnings
              <span className="flex h-3.5 w-6 items-center rounded-full bg-[#0a84ff] px-0.5">
                <span className="ml-auto h-2.5 w-2.5 rounded-full bg-white" />
              </span>
            </div>
          </div>

          {/* cards */}
          <div className="mb-3 grid grid-cols-[1fr_128px] gap-2.5">
            <div className="rounded-lg bg-[#23272f] p-3">
              <p className="text-[9px] uppercase tracking-wide text-white/40">
                Focus Activity
              </p>
              <p className="mb-3 text-[13px] font-semibold">Usage Statistics</p>
              <div className="flex h-16 items-end gap-2">
                {chart.map((h, i) => (
                  <div
                    key={i}
                    className="w-full flex-1 rounded-[2px] bg-[#0a84ff]"
                    style={{ height: `${h}%`, opacity: i === 0 ? 1 : 0.7 }}
                  />
                ))}
              </div>
              <div className="mt-1.5 flex gap-2">
                {xLabels.map((l, i) => (
                  <span
                    key={i}
                    className="flex-1 text-center text-[8px] text-white/35"
                  >
                    {l}
                  </span>
                ))}
              </div>
            </div>
            <div className="space-y-2.5">
              <div className="rounded-lg bg-[#23272f] p-2.5">
                <p className="text-[8px] uppercase tracking-wide text-white/40">
                  Total Worktime
                </p>
                <p className="my-1 text-[18px] font-semibold leading-none">
                  5h 45m
                </p>
                <p className="text-[8px] text-white/35">
                  Calculated from sessions
                </p>
              </div>
              <div className="rounded-lg bg-[#23272f] p-2.5">
                <p className="text-[8px] uppercase tracking-wide text-white/40">
                  Estimated Earnings
                </p>
                <p className="my-1 text-[18px] font-semibold leading-none">
                  €0,00
                </p>
                <p className="text-[8px] text-white/35">
                  Calculated from projects
                </p>
              </div>
            </div>
          </div>

          {/* ongoing activities */}
          <div className="mb-2 flex items-center justify-between">
            <span className="text-[12px] font-semibold">Ongoing Activities</span>
            <span className="rounded-md border border-white/10 px-2 py-1 text-[10px] text-white/65">
              Manage Projects
            </span>
          </div>
          <div className="space-y-1.5">
            {activities.map((a) => (
              <div
                key={a.name}
                className="flex items-center justify-between rounded-lg bg-[#20242c] px-3 py-2"
              >
                <div className="flex items-center gap-2">
                  <span
                    className="h-2 w-2 rounded-full"
                    style={{ background: a.color }}
                  />
                  <div>
                    <p className="text-[11px] font-medium leading-tight">
                      {a.name}
                    </p>
                    <p className="text-[9px] text-white/40">{a.company}</p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5 text-white/35">
                  <Check className="h-4 w-4 rounded bg-[#0a84ff] p-0.5 text-white" />
                  <Archive className="h-3.5 w-3.5" />
                  <Trash2 className="h-3.5 w-3.5" />
                </div>
              </div>
            ))}
          </div>

          <p className="mt-3 text-[9px] text-white/30">Apr 3, 2026</p>
        </div>
      </div>
    </div>
  );
}
