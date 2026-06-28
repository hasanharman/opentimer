import SwiftUI
import CoreData

struct DashboardSessionRow: View {
    let session: Session
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: session.project?.colorHex) ?? Color.accentColor)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.project?.name ?? "Project")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(session.project?.company?.name ?? "Company")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(TimeFormatter.hoursMinutes(from: duration))
                    .font(.subheadline)
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.dashboardCard)
        .cornerRadius(AppTheme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.dashboardStroke, lineWidth: 1)
        )
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = NSFetchRequest<Session>(entityName: "Session")
    let session = (try? context.fetch(request).first) ?? Session(context: context)
    return DashboardSessionRow(session: session, duration: 3600)
        .padding()
        .environment(\.managedObjectContext, context)
}
