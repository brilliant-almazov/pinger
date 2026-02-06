import Foundation
import Combine

/// Stores app settings in UserDefaults
final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Keys

    private enum Keys {
        static let targets = "pinger.targets"
        static let pingInterval = "pinger.pingInterval"
        static let badPingThreshold = "pinger.badPingThreshold"
        static let isPaused = "pinger.isPaused"
        static let notificationsEnabled = "pinger.notificationsEnabled"
    }

    // MARK: - Published Properties

    @Published var targets: [PingTarget] {
        didSet { saveTargets() }
    }

    @Published var pingInterval: TimeInterval {
        didSet { defaults.set(pingInterval, forKey: Keys.pingInterval) }
    }

    @Published var badPingThreshold: Int {
        didSet { defaults.set(badPingThreshold, forKey: Keys.badPingThreshold) }
    }

    @Published var isPaused: Bool {
        didSet { defaults.set(isPaused, forKey: Keys.isPaused) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    // MARK: - Computed Properties

    var enabledTargets: [PingTarget] {
        targets.filter { $0.isEnabled }
    }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load targets
        if let data = defaults.data(forKey: Keys.targets),
           let decoded = try? decoder.decode([PingTarget].self, from: data) {
            self.targets = decoded
        } else {
            self.targets = PingTarget.defaults
        }

        // Load other settings with defaults
        self.pingInterval = defaults.object(forKey: Keys.pingInterval) as? TimeInterval ?? 1.0
        self.badPingThreshold = defaults.object(forKey: Keys.badPingThreshold) as? Int ?? 100
        self.isPaused = defaults.bool(forKey: Keys.isPaused)
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
    }

    // MARK: - Target Management

    func addTarget(_ target: PingTarget) {
        targets.append(target)
    }

    func removeTarget(at index: Int) {
        guard targets.indices.contains(index) else { return }
        targets.remove(at: index)
    }

    func removeTarget(id: UUID) {
        targets.removeAll { $0.id == id }
    }

    func updateTarget(_ target: PingTarget) {
        guard let index = targets.firstIndex(where: { $0.id == target.id }) else { return }
        targets[index] = target
    }

    func toggleTarget(id: UUID) {
        guard let index = targets.firstIndex(where: { $0.id == id }) else { return }
        targets[index].isEnabled.toggle()
    }

    // MARK: - Reset

    func resetToDefaults() {
        targets = PingTarget.defaults
        pingInterval = 1.0
        badPingThreshold = 100
        isPaused = false
        notificationsEnabled = true
    }

    // MARK: - Private

    private func saveTargets() {
        guard let data = try? encoder.encode(targets) else { return }
        defaults.set(data, forKey: Keys.targets)
    }
}
