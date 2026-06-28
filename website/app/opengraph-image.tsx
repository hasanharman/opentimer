import { ImageResponse } from "next/og";

export const alt =
  "Freelance Timer — track freelance work right from your menu bar";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const bars = [60, 34, 92, 28, 54, 20, 14];

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 90px",
          background:
            "linear-gradient(135deg, #1f63f5 0%, #1646c6 38%, #0d2f93 70%, #071e63 100%)",
          fontFamily: "sans-serif",
          color: "white",
        }}
      >
        {/* left: copy */}
        <div style={{ display: "flex", flexDirection: "column", maxWidth: 600 }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: 600,
              color: "rgba(255,255,255,0.8)",
            }}
          >
            <div
              style={{
                width: 13,
                height: 13,
                borderRadius: 99,
                background: "#34c759",
                display: "flex",
              }}
            />
            FREE · OPEN SOURCE · macOS 13+
          </div>

          <div
            style={{
              display: "flex",
              flexDirection: "column",
              marginTop: 30,
              fontSize: 74,
              fontWeight: 700,
              lineHeight: 1.05,
              letterSpacing: -2,
            }}
          >
            <span>Track freelance work,</span>
            <span style={{ color: "rgba(255,255,255,0.62)" }}>
              from your menu bar
            </span>
          </div>

          <div
            style={{
              display: "flex",
              fontSize: 27,
              marginTop: 32,
              lineHeight: 1.4,
              color: "rgba(255,255,255,0.82)",
            }}
          >
            A native macOS timer for projects, earnings, and summaries — all
            stored on your Mac.
          </div>
        </div>

        {/* right: timer card */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            width: 300,
            padding: 26,
            borderRadius: 26,
            background: "#0b1830",
            border: "1px solid rgba(255,255,255,0.1)",
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              fontSize: 19,
              fontWeight: 600,
            }}
          >
            <span>Freelance Timer</span>
            <span style={{ color: "rgba(255,255,255,0.4)" }}>×</span>
          </div>

          <div
            style={{
              display: "flex",
              fontSize: 14,
              marginTop: 24,
              color: "rgba(255,255,255,0.4)",
            }}
          >
            Tracking…
          </div>

          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              marginTop: 6,
            }}
          >
            <span style={{ fontSize: 50, fontWeight: 700, letterSpacing: -1 }}>
              01:24:36
            </span>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                width: 56,
                height: 56,
                borderRadius: 99,
                background: "#0a84ff",
                gap: 6,
              }}
            >
              <div
                style={{
                  width: 6,
                  height: 20,
                  background: "white",
                  borderRadius: 2,
                  display: "flex",
                }}
              />
              <div
                style={{
                  width: 6,
                  height: 20,
                  background: "white",
                  borderRadius: 2,
                  display: "flex",
                }}
              />
            </div>
          </div>

          <div
            style={{
              display: "flex",
              alignItems: "flex-end",
              gap: 8,
              height: 64,
              marginTop: 30,
            }}
          >
            {bars.map((h, i) => (
              <div
                key={i}
                style={{
                  display: "flex",
                  flex: 1,
                  height: `${h}%`,
                  borderRadius: 3,
                  background: "#0a84ff",
                  opacity: i === 2 ? 1 : 0.5,
                }}
              />
            ))}
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}
