import SwiftUI

enum AppTheme {
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let windowBackground = Color(NSColor.windowBackgroundColor)
    static let separator = Color(NSColor.separatorColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)

    static let dashboardBackground = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let sidebarBackground = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let dashboardCard = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let dashboardCardElevated = Color(red: 0.16, green: 0.16, blue: 0.20)
    static let dashboardStroke = Color.white.opacity(0.06)
    static let dashboardMuted = Color.white.opacity(0.55)

    static let cardCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct DashboardCardStyle: ViewModifier {
    var elevated = false

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(elevated ? AppTheme.dashboardCardElevated : AppTheme.dashboardCard)
            .cornerRadius(AppTheme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(AppTheme.dashboardStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
    }
}

extension View {
    func dashboardCardStyle(elevated: Bool = false) -> some View {
        modifier(DashboardCardStyle(elevated: elevated))
    }
}
