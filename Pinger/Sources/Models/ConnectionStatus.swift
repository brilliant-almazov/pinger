import Foundation
import SwiftUI

/// Represents the current connection status
enum ConnectionStatus: Equatable {
    case good           // All targets responding, low latency
    case degraded       // All targets responding, high latency
    case partial        // Some targets not responding
    case offline        // No targets responding
    case paused         // Monitoring paused
    case unknown        // No data yet

    /// SF Symbol name for this status
    var symbolName: String {
        switch self {
        case .good: return "circle.fill"
        case .degraded: return "circle.fill"
        case .partial: return "circle.fill"
        case .offline: return "circle.fill"
        case .paused: return "pause.circle.fill"
        case .unknown: return "circle.dashed"
        }
    }

    /// Color for this status
    var color: Color {
        switch self {
        case .good: return .green
        case .degraded: return .yellow
        case .partial: return .orange
        case .offline: return .red
        case .paused: return .gray
        case .unknown: return .gray
        }
    }

    /// Emoji representation
    var emoji: String {
        switch self {
        case .good: return "🟢"
        case .degraded: return "🟡"
        case .partial: return "🟠"
        case .offline: return "🔴"
        case .paused: return "⏸"
        case .unknown: return "⏳"
        }
    }

    /// Human-readable description
    var description: String {
        switch self {
        case .good: return "Connected"
        case .degraded: return "Slow connection"
        case .partial: return "Partial connection"
        case .offline: return "Offline"
        case .paused: return "Paused"
        case .unknown: return "Checking..."
        }
    }
}
