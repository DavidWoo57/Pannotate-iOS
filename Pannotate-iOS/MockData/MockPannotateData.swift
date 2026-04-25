import Foundation

enum MockPannotateData {
    static let projects = [
        Project(title: "Urban Sunset", clipCount: 8, updatedAt: "2 hours ago", thumbnail: .city),
        Project(title: "Ocean Waves", clipCount: 5, updatedAt: "Yesterday", thumbnail: .ocean),
        Project(title: "Forest Path", clipCount: 12, updatedAt: "3 days ago", thumbnail: .forest)
    ]

    static let generatedClips = [
        GeneratedClip(title: "Urban Sunset - Scene 1", duration: "4s", createdAt: "5 min ago", status: .done, thumbnail: .city),
        GeneratedClip(title: "Forest Path - Scene 3", duration: "4s", createdAt: "Processing", status: .processing(65), thumbnail: .forest),
        GeneratedClip(title: "City Lights - Opening", duration: "6s", createdAt: "Queued", status: .queued, thumbnail: .lights)
    ]

    static let sequenceClips = [
        SequenceClip(title: "Urban Sunset - Scene 1", order: 1, duration: "4s", continuesFromPreviousFrame: false, thumbnail: .city),
        SequenceClip(title: "Urban Sunset - Scene 2", order: 2, duration: "3s", continuesFromPreviousFrame: true, thumbnail: .city),
        SequenceClip(title: "Ocean Waves", order: 3, duration: "5s", continuesFromPreviousFrame: false, thumbnail: .ocean),
        SequenceClip(title: "Forest Path", order: 4, duration: "4s", continuesFromPreviousFrame: false, thumbnail: .forest)
    ]

    static let profile = UserProfile(
        name: "Jordan Davis",
        handle: "@jordan.davis",
        plan: "Pro Creator",
        monthlyCreditsUsed: 340,
        monthlyCreditsTotal: 500,
        projectCount: 12,
        clipCount: 47,
        exportCount: 8
    )

    static let activity = [
        ActivityItem(title: "Urban Sunset exported", timeAgo: "2h ago", thumbnail: .city),
        ActivityItem(title: "Ocean Waves clip generated", timeAgo: "5h ago", thumbnail: .ocean),
        ActivityItem(title: "Forest Path draft saved", timeAgo: "Yesterday", thumbnail: .forest)
    ]
}
