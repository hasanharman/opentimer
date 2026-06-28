"use client";

import { useEffect, useState } from "react";
import { Apple, Wifi, BatteryMedium, Search, Timer } from "lucide-react";
import { site } from "@/lib/site";

function useClock() {
  const [now, setNow] = useState<string>("");
  useEffect(() => {
    const tick = () => {
      const d = new Date();
      const day = d.toLocaleDateString("en-US", { weekday: "short" });
      const time = d.toLocaleTimeString("en-US", {
        hour: "numeric",
        minute: "2-digit",
      });
      setNow(`${day} ${time}`);
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);
  return now;
}

/**
 * Full-width macOS menu bar. The Freelance Timer status item on the right is
 * "open" (highlighted) — the popover drops down from it, just like the real app.
 */
export function MacMenuBar() {
  const clock = useClock();

  return (
    <div className="sticky top-0 z-50 flex h-[30px] items-center justify-between bg-black/25 px-4 text-[13px] font-medium text-white backdrop-blur-md">
      {/* left: apple + focused app */}
      <div className="flex items-center gap-4">
        <Apple className="h-4 w-4 fill-white" />
        <span className="font-semibold tracking-tight">{site.name}</span>
      </div>

      {/* right: status items — the Timer item is the one that's open */}
      <div className="flex items-center gap-3.5 text-white/90">
        <Search className="hidden h-3.5 w-3.5 sm:block" />
        <BatteryMedium className="hidden h-[18px] w-[18px] sm:block" />
        <Wifi className="hidden h-4 w-4 sm:block" />
        <span className="-mx-1 flex items-center gap-1.5 rounded-md bg-white/20 px-1.5 py-0.5">
          <Timer className="h-[15px] w-[15px]" />
        </span>
        <span className="tabular min-w-[92px] text-right text-[12px]">
          {clock || " "}
        </span>
      </div>
    </div>
  );
}
