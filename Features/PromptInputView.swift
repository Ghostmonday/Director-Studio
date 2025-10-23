// MODULE: PromptInputView
// VERSION: 1.0.0
// PURPOSE: User input view for video generation prompts

import SwiftUI

struct PromptInputView: View {
    @State private var promptText = ""
    @ObservedObject var coordinator: Coordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Your Prompt")
                .font(.title2)
                .fontWeight(.semibold)
            
            TextEditor(text: $promptText)
                .frame(minHeight: 100)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Button("Generate Video") {
                // TODO: Process prompt
                coordinator.navigateTo(.clipPreview)
            }
            .buttonStyle(.borderedProminent)
            .disabled(promptText.isEmpty)
        }
        .padding()
    }
}
