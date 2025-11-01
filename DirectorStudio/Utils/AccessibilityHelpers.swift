import SwiftUI

extension DynamicTypeSize {
    var scale: Double {
        switch self {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .xLarge: return 1.2
        case .xxLarge: return 1.3
        case .xxxLarge: return 1.4
        case .accessibility1: return 1.5
        case .accessibility2: return 1.6
        case .accessibility3: return 1.7
        case .accessibility4: return 1.8
        case .accessibility5: return 1.9
        @unknown default: return 1.0
        }
    }
}

