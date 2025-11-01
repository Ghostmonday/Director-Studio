// MODULE: OrientationAwareLayout
// VERSION: 1.0.0
// PURPOSE: Adaptive layouts that respond to device orientation changes

import SwiftUI

// MARK: - Orientation Observer
class OrientationObserver: ObservableObject {
    @Published var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @Published var isLandscape: Bool = false
    @Published var isPortrait: Bool = true
    
    private var notificationObserver: NSObjectProtocol?
    
    init() {
        updateOrientation()
        
        notificationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateOrientation()
        }
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func updateOrientation() {
        orientation = UIDevice.current.orientation
        
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            isLandscape = true
            isPortrait = false
        case .portrait, .portraitUpsideDown:
            isLandscape = false
            isPortrait = true
        default:
            // Keep previous state for face up/down or unknown
            break
        }
    }
}

// MARK: - Orientation Aware View Modifier
struct OrientationAwareModifier: ViewModifier {
    @StateObject private var orientationObserver = OrientationObserver()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let portraitContent: () -> AnyView
    let landscapeContent: () -> AnyView
    
    var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    func body(content: Content) -> some View {
        Group {
            if orientationObserver.isLandscape && !isCompact {
                landscapeContent()
            } else {
                portraitContent()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: orientationObserver.isLandscape)
    }
}

// MARK: - Adaptive Grid Layout
struct AdaptiveGridLayout: View {
    @StateObject private var orientationObserver = OrientationObserver()
    let items: [AnyView]
    let portraitColumns: Int
    let landscapeColumns: Int
    let spacing: CGFloat
    
    private var columnCount: Int {
        orientationObserver.isLandscape ? landscapeColumns : portraitColumns
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount),
            spacing: spacing
        ) {
            ForEach(0..<items.count, id: \.self) { index in
                items[index]
            }
        }
        .animation(.easeInOut, value: columnCount)
    }
}

// MARK: - Split View Controller
struct AdaptiveSplitView<Primary: View, Secondary: View>: View {
    @StateObject private var orientationObserver = OrientationObserver()
    @State private var splitRatio: CGFloat = 0.4
    
    let primary: () -> Primary
    let secondary: () -> Secondary
    let minPrimaryWidth: CGFloat
    let allowHiding: Bool
    
    init(
        minPrimaryWidth: CGFloat = 300,
        allowHiding: Bool = true,
        @ViewBuilder primary: @escaping () -> Primary,
        @ViewBuilder secondary: @escaping () -> Secondary
    ) {
        self.minPrimaryWidth = minPrimaryWidth
        self.allowHiding = allowHiding
        self.primary = primary
        self.secondary = secondary
    }
    
    var body: some View {
        GeometryReader { geometry in
            if orientationObserver.isLandscape {
                // Landscape: Side-by-side
                HStack(spacing: 0) {
                    primary()
                        .frame(width: geometry.size.width * splitRatio)
                    
                    Divider()
                    
                    secondary()
                        .frame(maxWidth: .infinity)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newRatio = value.location.x / geometry.size.width
                            splitRatio = max(0.2, min(0.8, newRatio))
                        }
                )
            } else {
                // Portrait: Stacked or overlay
                ZStack {
                    secondary()
                    
                    if !allowHiding {
                        VStack {
                            primary()
                                .frame(height: geometry.size.height * 0.4)
                                .background(.regularMaterial)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Responsive Text
struct ResponsiveText: View {
    let text: String
    let portraitFont: Font
    let landscapeFont: Font
    
    @StateObject private var orientationObserver = OrientationObserver()
    
    init(
        _ text: String,
        portrait: Font = .body,
        landscape: Font = .title3
    ) {
        self.text = text
        self.portraitFont = portrait
        self.landscapeFont = landscape
    }
    
    var body: some View {
        Text(text)
            .font(orientationObserver.isLandscape ? landscapeFont : portraitFont)
    }
}

// MARK: - Orientation Specific Padding
struct OrientationPadding: ViewModifier {
    @StateObject private var orientationObserver = OrientationObserver()
    let portraitPadding: EdgeInsets
    let landscapePadding: EdgeInsets
    
    func body(content: Content) -> some View {
        content
            .padding(orientationObserver.isLandscape ? landscapePadding : portraitPadding)
    }
}

// MARK: - View Extensions
extension View {
    func orientationAware<Portrait: View, Landscape: View>(
        @ViewBuilder portrait: @escaping () -> Portrait,
        @ViewBuilder landscape: @escaping () -> Landscape
    ) -> some View {
        self.modifier(OrientationAwareModifier(
            portraitContent: { AnyView(portrait()) },
            landscapeContent: { AnyView(landscape()) }
        ))
    }
    
    func orientationPadding(
        portrait: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        landscape: EdgeInsets = EdgeInsets(top: 10, leading: 40, bottom: 10, trailing: 40)
    ) -> some View {
        self.modifier(OrientationPadding(
            portraitPadding: portrait,
            landscapePadding: landscape
        ))
    }
    
    // Disabled for iPhone-only app
    /*
    func adaptiveColumns(portrait: Int = 2, landscape: Int = 4) -> some View {
        self.modifier(AdaptiveColumnsModifier(
            portraitColumns: portrait,
            landscapeColumns: landscape
        ))
    }
    */
}

// MARK: - Adaptive Columns Modifier (Disabled for iPhone-only app)
/*
struct AdaptiveColumnsModifier: ViewModifier {
    @StateObject private var orientationObserver = OrientationObserver()
    let portraitColumns: Int
    let landscapeColumns: Int
    
    func body(content: Content) -> some View {
        content
            .environment(
                \.gridColumns,
                orientationObserver.isLandscape ? landscapeColumns : portraitColumns
            )
    }
}
*/

// MARK: - Orientation-Aware Container
struct OrientationAwareContainer<Content: View>: View {
    @StateObject private var orientationObserver = OrientationObserver()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let content: (Bool, CGSize) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            content(
                orientationObserver.isLandscape,
                geometry.size
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Example Usage
struct OrientationDemoView: View {
    var body: some View {
        OrientationAwareContainer { isLandscape, size in
            Group {
                if isLandscape {
                    // Landscape layout
                    HStack {
                        // Sidebar
                        VStack {
                            Text("Sidebar")
                                .font(.title)
                            Spacer()
                        }
                        .frame(width: size.width * 0.3)
                        .background(Color.gray.opacity(0.2))
                        
                        // Main content
                        VStack {
                            Text("Main Content")
                                .font(.largeTitle)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // Portrait layout
                    VStack {
                        Text("Portrait Mode")
                            .font(.largeTitle)
                        Spacer()
                    }
                }
            }
        }
    }
}
