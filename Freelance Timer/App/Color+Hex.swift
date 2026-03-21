import SwiftUI

extension Color {
    init?(hex: String?) {
        guard let hex, let int = Int(hex, radix: 16) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let uiColor = NSColor(self)
        guard let rgb = uiColor.usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

enum ProjectColor: String, CaseIterable, Identifiable {
    case blue = "3B82F6"
    case teal = "14B8A6"
    case green = "22C55E"
    case yellow = "EAB308"
    case orange = "F97316"
    case red = "EF4444"
    case purple = "8B5CF6"

    var id: String { rawValue }
    var color: Color { Color(hex: rawValue) ?? .accentColor }
}
