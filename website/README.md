# Freelance Timer — Website

Marketing landing page for the Freelance Timer macOS app. Built with Next.js
(App Router), Tailwind CSS v4, and Motion.

The signature hero is a faux macOS desktop with a **live, ticking** recreation
of the app's menu bar popover (`components/TimerWidget.tsx`).

## Develop

```bash
cd website
pnpm install
pnpm dev          # http://localhost:3000
```

## Build

```bash
pnpm build
pnpm start
```

## Structure

```
website/
├── app/
│   ├── layout.tsx        # metadata, fonts, <html>
│   ├── page.tsx          # menu bar + hero
│   └── globals.css       # Tailwind v4 theme + helpers
├── components/
│   ├── MacMenuBar.tsx    # full-width macOS menu bar with live clock
│   ├── Hero.tsx          # full-screen desktop scene
│   └── TimerWidget.tsx   # live menu bar popover (the hero centerpiece)
└── lib/site.ts           # links, version, requirements (edit here)
```

## Editing content

- Links, version, and requirements live in `lib/site.ts`.
- Update the download link by changing `repo` there (`releasesLatest` is derived
  from it).

## Deploy (Vercel)

Set the project root to `website/` (or run `vercel` from inside it). It's a fully
static export — no server, no env vars required.
