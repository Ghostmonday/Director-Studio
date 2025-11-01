import WidgetKit
import SwiftUI

struct RecentClipsWidget: Widget {
    let kind: String = "RecentClipsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentClipsProvider()) { entry in
            RecentClipsEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Clips")
        .description("Quick access to your last 5 clips")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RecentClipsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentClipsEntry {
        RecentClipsEntry(date: Date(), clips: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RecentClipsEntry) -> Void) {
        let entry = RecentClipsEntry(date: Date(), clips: loadRecentClips())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentClipsEntry>) -> Void) {
        let entry = RecentClipsEntry(date: Date(), clips: loadRecentClips())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadRecentClips() -> [WidgetClip] {
        guard let data = UserDefaults(suiteName: "group.com.directorstudio.app")?.data(forKey: "recent_clips"),
              let clips = try? JSONDecoder().decode([WidgetClip].self, from: data) else {
            return []
        }
        return Array(clips.prefix(5))
    }
}

struct RecentClipsEntry: TimelineEntry {
    let date: Date
    let clips: [WidgetClip]
}

struct WidgetClip: Codable, Identifiable {
    let id: String
    let name: String
    let thumbnailData: Data?
}

struct RecentClipsEntryView: View {
    var entry: RecentClipsProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Clips")
                .font(.headline)
            
            if entry.clips.isEmpty {
                Text("No clips yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(entry.clips) { clip in
                    HStack {
                        if let data = clip.thumbnailData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Text(clip.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}

