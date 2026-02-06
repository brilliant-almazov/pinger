import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var contextMenu: NSMenu?
    private var settingsWindow: NSWindow?
    private var coordinator: AppCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator = AppCoordinator()
        setupStatusItem()
        setupPopover()
        setupContextMenu()
        setupBindings()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "⏳ --"
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        guard let coordinator = coordinator else { return }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 180)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuContentView(coordinator: coordinator)
        )
    }

    private func setupContextMenu() {
        contextMenu = NSMenu()

        let pauseItem = NSMenuItem(
            title: "Pause",
            action: #selector(togglePause),
            keyEquivalent: ""
        )
        pauseItem.target = self
        contextMenu?.addItem(pauseItem)

        contextMenu?.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        contextMenu?.addItem(settingsItem)

        contextMenu?.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        contextMenu?.addItem(quitItem)
    }

    private func setupBindings() {
        coordinator?.$displayText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
                let attributes: [NSAttributedString.Key: Any] = [.font: font]
                self?.statusItem?.button?.attributedTitle = NSAttributedString(string: text, attributes: attributes)
            }
            .store(in: &cancellables)

        // Update tooltip with details
        coordinator?.historyStore.$latestResults
            .combineLatest(coordinator!.settingsStore.$targets)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results, targets in
                self?.updateTooltip(results: results, targets: targets)
            }
            .store(in: &cancellables)

        // Update pause menu item title
        coordinator?.settingsStore.$isPaused
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPaused in
                if let pauseItem = self?.contextMenu?.item(at: 0) {
                    pauseItem.title = isPaused ? "Resume" : "Pause"
                }
            }
            .store(in: &cancellables)
    }

    private func updateTooltip(results: [UUID: PingResult], targets: [PingTarget]) {
        let lines = targets.compactMap { target -> String? in
            guard target.isEnabled else { return nil }
            if let result = results[target.id] {
                let status = result.isSuccess ? "✓" : "✗"
                let latency = result.latencyMs.map { "\($0)ms" } ?? "--"
                return "\(status) \(target.name): \(latency)"
            } else {
                return "⏳ \(target.name): --"
            }
        }
        statusItem?.button?.toolTip = lines.isEmpty ? "Pinger" : lines.joined(separator: "\n")
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startEventMonitor()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func showContextMenu() {
        guard let button = statusItem?.button, let menu = contextMenu else { return }
        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func togglePause() {
        coordinator?.togglePause()
    }

    @objc private func openSettings() {
        guard let coordinator = coordinator else { return }

        if settingsWindow == nil {
            let settingsView = SettingsView(settingsStore: coordinator.settingsStore)
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "Pinger Settings"
            settingsWindow?.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            settingsWindow?.setContentSize(NSSize(width: 400, height: 420))
            settingsWindow?.minSize = NSSize(width: 350, height: 380)
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        coordinator?.quit()
    }
}
