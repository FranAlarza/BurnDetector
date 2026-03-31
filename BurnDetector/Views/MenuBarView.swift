import SwiftUI

struct MenuBarView: View {
    @Bindable var viewModel: MenuBarViewModel
    @Environment(\.openSettings) private var openSettings

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BurnDetector")
                    .font(.headline)

                Spacer()

                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }

            Text(cpuLabel)
                .font(.body)
                .foregroundStyle(.secondary)

            if viewModel.permissionsError {
                Text("Permissions required to read CPU usage")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 220)
    }

    // MARK: - Private

    private var cpuLabel: String {
        if let usage = viewModel.cpuUsage {
            return "CPU: \(usage)%"
        }
        return "CPU: --%"
    }
}
