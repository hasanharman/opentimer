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
│   ├── page.tsx          # composes the sections
│   └── globals.css       # Tailwind v4 theme + helpers
├── components/
│   ├── Nav.tsx
│   ├── Hero.tsx          # macOS desktop scene + menu bar
│   ├── TimerWidget.tsx   # live menu bar popover (the hero centerpiece)
│   ├── Features.tsx
│   ├── Screenshots.tsx   # uses /public/screenshots/*
│   ├── Download.tsx
│   └── Footer.tsx
├── lib/site.ts           # links, version, feature copy (edit here)
└── public/screenshots/   # copied from ../screenshots
```

## Editing content

- Links, version, requirements, and feature copy live in `lib/site.ts`.
- Update the download link by changing `releasesLatest` there.
- Screenshots are copied from the repo's `../screenshots`. Re-copy when they
  change: `cp ../screenshots/{main,menubar,project-detail}.png public/screenshots/`

## Deploy (Vercel)

Set the project root to `website/` (or run `vercel` from inside it). It's a fully
static export — no server, no env vars required.
