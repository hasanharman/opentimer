import SwiftUI

struct SegmentedTabs<Selection: Hashable>: View {
    let items: [Selection]
    @Binding var selection: Selection
    let label: (Selection) -> String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(label(item))
                        .font(.callout)
                        .fontWeight(selection == item ? .semibold : .regular)
                        .foregroundColor(selection == item ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    Capsule()
                        .fill(selection == item ? Color.accentColor : Color.clear)
                )
            }
        }
        .padding(6)
        .background(AppTheme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    SegmentedTabs(items: SummaryRange.allCases, selection: .constant(.week)) { $0.rawValue }
        .padding()
}
