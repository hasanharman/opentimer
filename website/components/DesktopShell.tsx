"use client";

import { useState } from "react";
import { MacMenuBar } from "./MacMenuBar";
import { Hero } from "./Hero";

export type View = "widget" | "app" | "closed";

/**
 * Owns the "running app" state so the menu bar and the hero stay in sync —
 * only one of {widget, main window} is ever visible, just like the real app.
 */
export function DesktopShell({ stars }: { stars: number | null }) {
  const [view, setView] = useState<View>("widget");

  return (
    <main>
      <MacMenuBar
        active={view === "widget"}
        onTimerClick={() =>
          setView((v) => (v === "widget" ? "closed" : "widget"))
        }
      />
      <Hero
        stars={stars}
        view={view}
        onOpenApp={() => setView("app")}
        onCloseWidget={() => setView("closed")}
        onCloseApp={() => setView("widget")}
      />
    </main>
  );
}
