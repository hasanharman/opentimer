# Open Timer — Website

Marketing landing page for the Open Timer macOS app. Built with Next.js
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

1. Import the repo at [vercel.com](https://vercel.com) → **Add New… → Project**.
2. Set **Root Directory** to `website` (the app lives in this subfolder).
3. Vercel auto-detects Next.js + pnpm — accept the defaults and **Deploy**.

It runs as a standard Next.js app: the GitHub star count is fetched in a server
component and revalidates hourly (`revalidate: 3600`), so it stays fresh without
manual rebuilds.

**Custom domain:** add it under the project's **Settings → Domains**, then set an
env var `NEXT_PUBLIC_SITE_URL=https://yourdomain.com` so OG/canonical URLs match.
Without it, the metadata falls back to the Vercel production URL automatically.
