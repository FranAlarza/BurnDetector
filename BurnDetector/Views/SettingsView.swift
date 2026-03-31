import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings

    // MARK: - Body

    var body: some View {
        Form {
            Section("Alerts") {
                Toggle("Sound alerts", isOn: $settings.soundEnabled)

                VStack(alignment: .leading, spacing: 4) {
                    Text("CPU Threshold: \(settings.threshold)%")
                    Slider(
                        value: thresholdBinding,
                        in: 50...100,
                        step: 1
                    )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 150)
    }

    // MARK: - Private

    private var thresholdBinding: Binding<Double> {
        Binding(
            get: { Double(settings.threshold) },
            set: { settings.threshold = Int($0) }
        )
    }
}
