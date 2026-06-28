import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case activities = "Activities"
    case projects = "Projects"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .activities: return "clock"
        case .projects: return "folder"
        }
    }
}

struct DashboardSidebarView: View {
    @Binding var selection: DashboardSection
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 6) {
                ForEach(DashboardSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: section.systemImage)
                                .frame(width: 18)
                            Text(section.rawValue)
                                .font(.callout)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(selection == section ? Color.white.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(selection == section ? .white : AppTheme.dashboardMuted)
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                        .frame(width: 18)
                    Text("Settings")
                        .font(.callout)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
        }
        .padding(16)
        .frame(width: 210)
        .background(AppTheme.sidebarBackground)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

#Preview {
    DashboardSidebarView(selection: .constant(.dashboard), showSettings: .constant(false))
        .frame(height: 700)
}
