import SwiftUI
import Combine

struct MenuBarLabelView: View {
    @EnvironmentObject private var sessionController: SessionController

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if sessionController.activeSession != nil {
            HStack(spacing: 4) {
                Text(sessionController.menuBarTitle(now: now))
                    .lineLimit(1)
                    .monospacedDigit()
                Image(systemName: sessionController.isRunning ? "play.circle.fill" : "pause.circle")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .onReceive(timer) { value in
                now = value
            }
        } else {
            Image(systemName: "stopwatch")
        }
    }
}

#Preview {
    MenuBarLabelView()
        .environmentObject(SessionController(viewContext: PersistenceController.preview.container.viewContext))
        .padding()
}
