import SwiftUI

struct MenuContentView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with status
            headerSection

            Divider()

            // Target list with individual statuses
            targetListSection
        }
        .padding()
        .frame(width: 260, height: 180)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Text(coordinator.statusCalculator.status.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(coordinator.statusCalculator.status.description)
                    .font(.headline)

                if let avgMs = coordinator.statusCalculator.averageLatencyMs {
                    Text("Avg: \(avgMs)ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    private var targetListSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Targets")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(coordinator.settingsStore.targets) { target in
                targetRow(target)
            }
        }
    }

    private func targetRow(_ target: PingTarget) -> some View {
        HStack {
            // Toggle for enable/disable
            Button(action: { coordinator.settingsStore.toggleTarget(id: target.id) }) {
                Image(systemName: target.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(target.isEnabled ? .green : .secondary)
            }
            .buttonStyle(.borderless)

            // Status indicator
            if target.isEnabled {
                if let result = coordinator.historyStore.latest(for: target.id) {
                    Text(result.isSuccess ? "🟢" : "🔴")
                        .font(.caption)
                } else {
                    Text("⏳")
                        .font(.caption)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(target.name)
                    .font(.subheadline)
                    .foregroundColor(target.isEnabled ? .primary : .secondary)
                Text(target.host)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if target.isEnabled,
               let result = coordinator.historyStore.latest(for: target.id),
               let ms = result.latencyMs {
                Text("\(ms)ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if target.isEnabled {
                Text("--")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
