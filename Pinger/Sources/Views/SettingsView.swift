import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @State private var newHost: String = ""
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Targets
            GroupBox("Targets") {
                VStack(spacing: 8) {
                    ForEach(settingsStore.targets) { target in
                        targetRow(target)
                    }

                    Divider()

                    // Add new
                    HStack(spacing: 8) {
                        TextField("IP or hostname", text: $newHost)
                            .textFieldStyle(.roundedBorder)

                        TextField("Name (optional)", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)

                        Button(action: addTarget) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(newHost.isEmpty)
                    }
                }
                .padding(8)
            }

            // Settings
            GroupBox("Settings") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Ping interval")
                        Spacer()
                        Picker("", selection: $settingsStore.pingInterval) {
                            Text("0.5s").tag(0.5)
                            Text("1s").tag(1.0)
                            Text("2s").tag(2.0)
                            Text("5s").tag(5.0)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    HStack {
                        Text("Slow threshold")
                        Spacer()
                        Picker("", selection: $settingsStore.badPingThreshold) {
                            Text("50ms").tag(50)
                            Text("100ms").tag(100)
                            Text("200ms").tag(200)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                }
                .padding(8)
            }

            Spacer()

            // Reset button
            HStack {
                Button("Reset to Defaults") {
                    settingsStore.resetToDefaults()
                }
                .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(20)
        .frame(minWidth: 380, minHeight: 380)
    }

    private func targetRow(_ target: PingTarget) -> some View {
        HStack(spacing: 12) {
            Button(action: { settingsStore.toggleTarget(id: target.id) }) {
                Image(systemName: target.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(target.isEnabled ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(target.name)
                    .fontWeight(.medium)
                Text(target.host)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { settingsStore.removeTarget(id: target.id) }) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func addTarget() {
        let name = newName.isEmpty ? newHost : newName
        let target = PingTarget(host: newHost, name: name)
        settingsStore.addTarget(target)
        newHost = ""
        newName = ""
    }
}
