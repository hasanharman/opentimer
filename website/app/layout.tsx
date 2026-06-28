import type { Metadata } from "next";
import "./globals.css";

// Resolve the canonical URL: a custom domain if set, otherwise Vercel's
// production URL, falling back to the intended domain for local builds.
const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ??
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "https://opentimer.app");

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "Open Timer — Track freelance work right from your menu bar",
  description:
    "A minimal, native macOS menu bar app to track freelance sessions by project — with earnings, summaries, charts, and local-only storage. Free and open source.",
  keywords: [
    "freelance time tracker",
    "macOS menu bar timer",
    "open timer",
    "time tracking app",
    "invoice hours",
    "SwiftUI app",
  ],
  authors: [{ name: "Hasan Harman" }],
  openGraph: {
    title: "Open Timer — Track freelance work from your menu bar",
    description:
      "Native macOS menu bar time tracker for freelancers. Projects, earnings, summaries, charts — all stored locally on your Mac.",
    url: siteUrl,
    siteName: "Open Timer",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Open Timer",
    description:
      "Native macOS menu bar time tracker for freelancers. Local-only, free, open source.",
  },
  icons: { icon: "/favicon.svg" },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
