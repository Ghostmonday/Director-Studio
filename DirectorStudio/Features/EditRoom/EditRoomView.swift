// MODULE: EditRoomView
// VERSION: 1.0.0
// PURPOSE: Voiceover recording interface with video playback sync

import SwiftUI
import AVFoundation

/// Edit room for voiceover recording
struct EditRoomView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = EditRoomViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Video preview area
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                
                if viewModel.isPlaying {
                    Image(systemName: "play.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Image(systemName: "film")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .cornerRadius(12)
            .padding()
            
            // Time marker
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.system(.body, design: .monospaced))
                
                Slider(value: $viewModel.currentTime, in: 0...viewModel.totalDuration)
                    .disabled(viewModel.isRecording)
                
                Text(formatTime(viewModel.totalDuration))
                    .font(.system(.body, design: .monospaced))
            }
            .padding(.horizontal)
            
            // Waveform visualization
            WaveformView(audioLevel: viewModel.audioLevel, isRecording: viewModel.isRecording)
                .frame(height: 80)
                .padding(.horizontal)
            
            // Recording controls
            HStack(spacing: 30) {
                // Play/Pause
                Button(action: {
                    viewModel.togglePlayback()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isRecording)
                
                // Record/Stop
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(viewModel.isRecording ? .red : .green)
                }
                
                // Save
                Button(action: {
                    viewModel.saveVoiceover(coordinator: coordinator)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                }
                .disabled(!viewModel.hasRecording)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Record Voiceover")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            viewModel.setup(clips: coordinator.generatedClips)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

/// Waveform visualization component
struct WaveformView: View {
    let audioLevel: CGFloat
    let isRecording: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                
                // Waveform bars
                HStack(spacing: 2) {
                    ForEach(0..<50) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isRecording ? Color.red : Color.gray)
                            .frame(width: 4)
                            .frame(height: CGFloat.random(in: 10...60) * (isRecording ? audioLevel : 0.3))
                            .animation(.easeInOut(duration: 0.1), value: audioLevel)
                    }
                }
                .padding(8)
            }
        }
    }
}

