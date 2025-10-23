// MODULE: PromptInputView
// VERSION: 1.0.0
// PURPOSE: User input view for video generation prompts

import SwiftUI

struct PromptInputView: View {
    @State private var promptText = ""
    @State private var isProcessing = false
    @ObservedObject var coordinator: Coordinator
    @EnvironmentObject var dataStore: LocalDataStore
    @EnvironmentObject var pipelineConnector: PipelineConnector
    
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
            
            if isProcessing {
                LoadingView()
            } else {
                Button("Generate Video") {
                    Task {
                        await processPrompt()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(promptText.isEmpty)
            }
            
            // Show recent jobs
            if !dataStore.jobs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Jobs")
                        .font(.headline)
                    
                    ForEach(dataStore.jobs.prefix(3)) { job in
                        HStack {
                            Text(job.prompt)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(job.status.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func processPrompt() async {
        isProcessing = true
        
        // Create new job
        let job = PromptJob(prompt: promptText)
        dataStore.saveJob(job)
        
        // Process through pipeline
        let result = await pipelineConnector.process(prompt: promptText)
        
        switch result {
        case .success(let clips):
            for clip in clips {
                dataStore.saveClip(clip)
            }
            coordinator.navigateTo(.clipPreview)
        case .failure(let error):
            print("Error: \(error)")
        }
        
        isProcessing = false
    }
}
