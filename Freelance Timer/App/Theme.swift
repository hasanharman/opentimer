import SwiftUI

enum AppTheme {
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let windowBackground = Color(NSColor.windowBackgroundColor)
    static let separator = Color(NSColor.separatorColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
