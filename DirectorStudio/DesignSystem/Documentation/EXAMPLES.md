# LensDepth Component Examples
**Real-world implementations**

## 📝 Script Input Screen

```swift
struct ScriptInputView: View {
    @State private var scriptText: String = ""
    @State private var wordCount: Int = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: LensDepthTokens.spacingOuter) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Script")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(LensDepthTokens.colorTextPrimary)
                    
                    Text("\(wordCount) words")
                        .font(.system(size: 13))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
                
                Spacer()
                
                Button(action: { /* clear */ }) {
                    Image(systemName: "trash")
                        .foregroundColor(LensDepthTokens.colorSemanticDanger)
                }
            }
            .padding(.horizontal, LensDepthTokens.spacingMargin)
            .padding(.top, LensDepthTokens.spacingMargin)
            
            // Script Editor
            TextEditor(text: $scriptText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(LensDepthTokens.colorTextPrimary)
                .focused($isTextFieldFocused)
                .padding(LensDepthTokens.spacingOuter)
                .background(LensDepthTokens.colorSurfacePanel)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isTextFieldFocused ? LensDepthTokens.colorPrimaryAmber : Color.clear,
                            lineWidth: 2
                        )
                )
                .padding(.horizontal, LensDepthTokens.spacingMargin)
                .onChange(of: scriptText) { newValue in
                    wordCount = newValue.split(separator: " ").count
                }
            
            // Quick Actions
            HStack(spacing: LensDepthTokens.spacingInner) {
                QuickActionButton(
                    icon: "sparkles",
                    title: "Enhance",
                    action: { /* enhance */ }
                )
                
                QuickActionButton(
                    icon: "doc.text",
                    title: "Template",
                    action: { /* template */ }
                )
                
                QuickActionButton(
                    icon: "square.and.arrow.down",
                    title: "Import",
                    action: { /* import */ }
                )
            }
            .padding(.horizontal, LensDepthTokens.spacingMargin)
            .padding(.bottom, LensDepthTokens.spacingMargin)
        }
        .background(LensDepthTokens.colorBackgroundBase)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(LensDepthTokens.colorTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LensDepthTokens.spacingInner)
            .background(LensDepthTokens.colorSurfacePanel)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

## 🎬 Generation Configuration Panel

```swift
struct GenerationConfigView: View {
    @State private var selectedMode: SegmentationMode = .ai
    @State private var targetDuration: Double = 5.0
    @State private var maxSegments: Int = 10
    @State private var enableSemanticExpansion: Bool = false
    
    var estimatedTokens: Int {
        // Calculation logic
        return Int(targetDuration) * maxSegments * 15
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: LensDepthTokens.spacingOuter) {
                // Header
                SectionHeader(
                    title: "Generation Settings",
                    icon: "slider.horizontal.3"
                )
                
                // Mode Selection
                ConfigSection(title: "Segmentation Mode") {
                    VStack(spacing: LensDepthTokens.spacingInner) {
                        ForEach(SegmentationMode.allCases, id: \.self) { mode in
                            ModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                onSelect: { selectedMode = mode }
                            )
                        }
                    }
                }
                
                // Duration Control
                ConfigSection(title: "Target Duration") {
                    VStack(spacing: LensDepthTokens.spacingInner) {
                        HStack {
                            Text("Duration per clip")
                                .foregroundColor(LensDepthTokens.colorTextSecondary)
                            
                            Spacer()
                            
                            Text("\(Int(targetDuration))s")
                                .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                                .font(.system(size: 17, weight: .semibold))
                        }
                        
                        Slider(
                            value: $targetDuration,
                            in: 1...20,
                            step: 1
                        )
                        .tint(LensDepthTokens.colorPrimaryAmber)
                    }
                    .padding(LensDepthTokens.spacingOuter)
                    .background(LensDepthTokens.colorSurfacePanel)
                    .cornerRadius(12)
                }
                
                // Segments Control
                ConfigSection(title: "Maximum Segments") {
                    VStack(spacing: LensDepthTokens.spacingInner) {
                        HStack {
                            Text("Number of clips")
                                .foregroundColor(LensDepthTokens.colorTextSecondary)
                            
                            Spacer()
                            
                            Text("\(maxSegments)")
                                .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                                .font(.system(size: 17, weight: .semibold))
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(maxSegments) },
                                set: { maxSegments = Int($0) }
                            ),
                            in: 1...100,
                            step: 1
                        )
                        .tint(LensDepthTokens.colorPrimaryAmber)
                    }
                    .padding(LensDepthTokens.spacingOuter)
                    .background(LensDepthTokens.colorSurfacePanel)
                    .cornerRadius(12)
                }
                
                // Advanced Options
                ConfigSection(title: "Advanced") {
                    Toggle(isOn: $enableSemanticExpansion) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Semantic Expansion")
                                .foregroundColor(LensDepthTokens.colorTextPrimary)
                            
                            Text("Enhance prompts with cinematic details")
                                .font(.system(size: 13))
                                .foregroundColor(LensDepthTokens.colorTextSecondary)
                        }
                    }
                    .tint(LensDepthTokens.colorPrimaryAmber)
                    .padding(LensDepthTokens.spacingOuter)
                    .background(LensDepthTokens.colorSurfacePanel)
                    .cornerRadius(12)
                }
                
                // Cost Estimate
                CostEstimateCard(tokens: estimatedTokens)
                
                // Generate Button
                LDPrimaryButton(
                    title: "Generate Narrative List",
                    action: { /* start generation */ }
                )
                .padding(.top, LensDepthTokens.spacingOuter)
            }
            .padding(LensDepthTokens.spacingMargin)
        }
        .background(LensDepthTokens.colorBackgroundBase)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(LensDepthTokens.colorPrimaryAmber)
            
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(LensDepthTokens.colorTextPrimary)
            
            Spacer()
        }
    }
}

struct ConfigSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LensDepthTokens.spacingInner) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(LensDepthTokens.colorTextPrimary)
            
            content
        }
    }
}

struct CostEstimateCard: View {
    let tokens: Int
    
    var cost: Double {
        Double(tokens) * 0.01 // Example calculation
    }
    
    var body: some View {
        HStack(spacing: LensDepthTokens.spacingOuter) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 32))
                .foregroundColor(LensDepthTokens.colorPrimaryAmber)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated Cost")
                    .font(.system(size: 13))
                    .foregroundColor(LensDepthTokens.colorTextSecondary)
                
                HStack(spacing: 8) {
                    Text("\(tokens)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                    
                    Text("tokens")
                        .font(.system(size: 15))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
                
                Text("≈ $\(String(format: "%.2f", cost))")
                    .font(.system(size: 13))
                    .foregroundColor(LensDepthTokens.colorTextSecondary)
            }
            
            Spacer()
        }
        .padding(LensDepthTokens.spacingOuter)
        .background(LensDepthTokens.colorSurfacePanel)
        .cornerRadius(12)
        .modifier(LensDepthShadow(depth: .surface))
    }
}
```

## 🎞️ Generation Progress View

```swift
struct GenerationProgressView: View {
    let totalSegments: Int
    @State private var currentSegment: Int = 0
    @State private var progress: Double = 0.0
    @State private var currentStatus: String = "Initializing..."
    
    var body: some View {
        VStack(spacing: LensDepthTokens.spacingMargin) {
            // Overall Progress
            VStack(spacing: LensDepthTokens.spacingOuter) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(
                            LensDepthTokens.colorSurfacePanel,
                            lineWidth: 8
                        )
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LensDepthTokens.colorPrimaryAmber,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.3), value: progress)
                    
                    VStack(spacing: 8) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                        
                        Text("\(currentSegment) / \(totalSegments)")
                            .font(.system(size: 15))
                            .foregroundColor(LensDepthTokens.colorTextSecondary)
                    }
                }
                .frame(width: 200, height: 200)
                
                // Status Text
                Text(currentStatus)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(LensDepthTokens.colorTextPrimary)
                    .multilineTextAlignment(.center)
            }
            
            // Segment List
            ScrollView {
                LazyVStack(spacing: LensDepthTokens.spacingInner) {
                    ForEach(0..<totalSegments, id: \.self) { index in
                        SegmentProgressRow(
                            index: index + 1,
                            status: segmentStatus(for: index)
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
            
            // Controls
            HStack(spacing: LensDepthTokens.spacingInner) {
                LDSecondaryButton(
                    title: "Pause",
                    action: { /* pause */ }
                )
                
                LDSecondaryButton(
                    title: "Cancel",
                    action: { /* cancel */ }
                )
            }
        }
        .padding(LensDepthTokens.spacingMargin)
        .background(LensDepthTokens.colorBackgroundBase)
    }
    
    func segmentStatus(for index: Int) -> SegmentStatus {
        if index < currentSegment {
            return .completed
        } else if index == currentSegment {
            return .inProgress
        } else {
            return .pending
        }
    }
}

enum SegmentStatus {
    case pending, inProgress, completed, failed
}

struct SegmentProgressRow: View {
    let index: Int
    let status: SegmentStatus
    
    var statusIcon: String {
        switch status {
        case .pending: return "circle"
        case .inProgress: return "circle.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .pending: return LensDepthTokens.colorTextSecondary
        case .inProgress: return LensDepthTokens.colorPrimaryAmber
        case .completed: return LensDepthTokens.colorSemanticSuccess
        case .failed: return LensDepthTokens.colorSemanticDanger
        }
    }
    
    var body: some View {
        HStack(spacing: LensDepthTokens.spacingInner) {
            Image(systemName: statusIcon)
                .font(.system(size: 20))
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            Text("Clip \(index)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(LensDepthTokens.colorTextPrimary)
            
            Spacer()
            
            if status == .inProgress {
                ProgressView()
                    .tint(LensDepthTokens.colorPrimaryAmber)
            }
        }
        .padding(LensDepthTokens.spacingInner)
        .background(LensDepthTokens.colorSurfacePanel)
        .cornerRadius(8)
    }
}
```

## 📊 Cost Confirmation Dialog

```swift
struct CostConfirmationDialog: View {
    let tokens: Int
    let segments: Int
    let totalDuration: TimeInterval
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var cost: Double {
        Double(tokens) * 0.01
    }
    
    var isHighCost: Bool {
        cost > 100.0
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Dialog
            VStack(spacing: LensDepthTokens.spacingMargin) {
                // Header
                VStack(spacing: LensDepthTokens.spacingInner) {
                    Image(systemName: isHighCost ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isHighCost ? LensDepthTokens.colorSemanticDanger : LensDepthTokens.colorPrimaryAmber)
                    
                    Text(isHighCost ? "High Cost Generation" : "Confirm Generation")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(LensDepthTokens.colorTextPrimary)
                }
                
                // Details
                VStack(spacing: LensDepthTokens.spacingOuter) {
                    DetailRow(label: "Segments", value: "\(segments)")
                    DetailRow(label: "Total Duration", value: "\(Int(totalDuration))s")
                    
                    Divider()
                        .background(LensDepthTokens.colorTextSecondary.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Token Cost")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(LensDepthTokens.colorTextPrimary)
                            
                            Spacer()
                            
                            Text("\(tokens)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                        }
                        
                        HStack {
                            Text("USD Equivalent")
                                .foregroundColor(LensDepthTokens.colorTextSecondary)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", cost))")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(LensDepthTokens.colorTextSecondary)
                        }
                    }
                }
                .padding(LensDepthTokens.spacingOuter)
                .background(LensDepthTokens.colorSurfacePanel)
                .cornerRadius(12)
                
                // Warning for high cost
                if isHighCost {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(LensDepthTokens.colorSemanticDanger)
                        
                        Text("This is a premium generation. Make sure you've reviewed all settings.")
                            .font(.system(size: 13))
                            .foregroundColor(LensDepthTokens.colorTextSecondary)
                            .lineSpacing(4)
                    }
                    .padding(LensDepthTokens.spacingInner)
                    .background(LensDepthTokens.colorSemanticDanger.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Actions
                HStack(spacing: LensDepthTokens.spacingInner) {
                    LDSecondaryButton(title: "Cancel", action: onCancel)
                    LDPrimaryButton(title: "Confirm & Generate", action: onConfirm)
                }
            }
            .padding(LensDepthTokens.spacingMargin)
            .frame(maxWidth: 500)
            .background(LensDepthTokens.colorSurfacePanel)
            .cornerRadius(16)
            .modifier(StainedGlassEffect(intensity: 1.0))
            .modifier(LensDepthShadow(depth: .modal))
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(LensDepthTokens.colorTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(LensDepthTokens.colorTextPrimary)
        }
    }
}
```

---

*These examples demonstrate real-world usage of the LensDepth design system. Copy and adapt as needed for your specific use case.* 🎬

