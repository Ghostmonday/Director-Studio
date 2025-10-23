// MODULE: Coordinator
// VERSION: 1.0.0
// PURPOSE: Navigation coordinator for app flow

import SwiftUI

class Coordinator: ObservableObject {
    @Published var currentView: AppView = .promptInput
    
    enum AppView {
        case promptInput
        case clipPreview
        case settings
    }
    
    func navigateTo(_ view: AppView) {
        currentView = view
    }
}
