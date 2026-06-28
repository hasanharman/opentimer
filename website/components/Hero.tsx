"use client";

import { motion } from "motion/react";
import { Apple } from "lucide-react";
import { TimerWidget } from "./TimerWidget";
import { site } from "@/lib/site";

export function Hero() {
  return (
    <section className="wallpaper relative overflow-hidden">
      {/* soft desktop light */}
      <div className="pointer-events-none absolute -left-32 -top-32 h-96 w-96 rounded-full bg-white/10 blur-3xl" />
      <div className="pointer-events-none absolute bottom-0 right-0 h-[28rem] w-[28rem] rounded-full bg-[#0a2a78]/40 blur-3xl" />

      <div className="mx-auto flex max-w-6xl flex-col px-6 py-14 lg:min-h-[calc(100svh-30px)] lg:justify-center lg:py-0">
        {/* hero copy */}
        <div className="relative z-10 max-w-xl text-white">
          <span className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-[12px] font-medium text-white/90 backdrop-blur-sm">
            <span className="h-1.5 w-1.5 rounded-full bg-[#34c759]" />
            Free &amp; open source · macOS 13+
          </span>

          <h1 className="mt-5 text-balance text-[44px] font-semibold leading-[1.04] tracking-[-0.02em] sm:text-[58px]">
            Track freelance work,{" "}
            <span className="text-white/65">right from your menu bar</span>
          </h1>

          <p className="mt-5 max-w-md text-pretty text-[17px] leading-relaxed text-white/80">
            A minimal, native macOS app that tracks your sessions by project —
            with earnings, summaries, and charts. Everything stays on your Mac.
            Just open it, make it yours, and get back to work.
          </p>

          <div className="mt-8 flex flex-wrap items-center gap-3">
            <a
              href={site.releasesLatest}
              className="inline-flex items-center gap-2 rounded-xl bg-white px-5 py-3 text-[15px] font-semibold text-[color:var(--color-ink)] shadow-lg shadow-black/20 transition hover:bg-white/90"
            >
              <Apple className="h-4 w-4 fill-current" />
              Download for Mac
              <span className="text-[color:var(--color-muted)]">
                {site.version}
              </span>
            </a>
            <a
              href={site.repo}
              className="inline-flex items-center gap-2 rounded-xl border border-white/25 bg-white/5 px-5 py-3 text-[15px] font-semibold text-white backdrop-blur-sm transition hover:bg-white/10"
            >
              View on GitHub
            </a>
          </div>

          <p className="mt-4 font-mono text-[12px] text-white/55">
            {site.requirements}
          </p>
        </div>

        {/* the popover — drops from the menu bar on desktop, flows below on mobile */}
        <motion.div
          initial={{ opacity: 0, y: -16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1], delay: 0.15 }}
          className="z-20 mt-12 flex origin-top justify-center lg:absolute lg:right-4 lg:top-2 lg:mt-0 lg:block"
        >
          <div className="float-slow">
            <TimerWidget />
          </div>
        </motion.div>
      </div>
    </section>
  );
}
