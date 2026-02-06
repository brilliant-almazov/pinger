import AppKit
import Combine

/// Main coordinator that wires all services together
final class AppCoordinator: ObservableObject {
    let settingsStore: SettingsStore
    let historyStore: HistoryStore
    let pingService: PingService
    let statusCalculator: StatusCalculator

    @Published var displayText: String = "⏳ --"

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.settingsStore = SettingsStore()
        self.historyStore = HistoryStore()
        self.pingService = PingService()
        self.statusCalculator = StatusCalculator(
            historyStore: historyStore,
            settingsStore: settingsStore
        )

        setupBindings()
    }

    private func setupBindings() {
        // Forward display text from status calculator
        statusCalculator.$displayText
            .assign(to: &$displayText)

        // Start/stop pinging based on pause state
        settingsStore.$isPaused
            .combineLatest(settingsStore.$targets, settingsStore.$pingInterval)
            .sink { [weak self] isPaused, targets, interval in
                guard let self = self else { return }
                if isPaused {
                    self.pingService.stop()
                } else {
                    self.startPinging(targets: targets, interval: interval)
                }
            }
            .store(in: &cancellables)
    }

    private func startPinging(targets: [PingTarget], interval: TimeInterval) {
        pingService.startContinuousPing(targets: targets, interval: interval)
            .sink { [weak self] results in
                self?.historyStore.add(results: results)
            }
            .store(in: &cancellables)
    }

    func togglePause() {
        settingsStore.isPaused.toggle()
    }

    func quit() {
        pingService.stop()
        NSApplication.shared.terminate(nil)
    }
}
