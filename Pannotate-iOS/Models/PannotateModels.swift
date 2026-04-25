import Foundation
import UIKit

struct Project: Identifiable {
    let id: UUID
    let title: String
    let clipCount: Int
    let updatedAt: String
    let thumbnail: ThumbnailStyle

    init(
        id: UUID = UUID(),
        title: String,
        clipCount: Int,
        updatedAt: String,
        thumbnail: ThumbnailStyle
    ) {
        self.id = id
        self.title = title
        self.clipCount = clipCount
        self.updatedAt = updatedAt
        self.thumbnail = thumbnail
    }
}

struct GeneratedClip: Identifiable {
    let id: UUID
    let title: String
    let duration: String
    let createdAt: String
    let status: ClipStatus
    let thumbnail: ThumbnailStyle
    let image: UIImage?

    init(
        id: UUID = UUID(),
        title: String,
        duration: String,
        createdAt: String,
        status: ClipStatus,
        thumbnail: ThumbnailStyle,
        image: UIImage? = nil
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.createdAt = createdAt
        self.status = status
        self.thumbnail = thumbnail
        self.image = image
    }
}

struct SequenceClip: Identifiable {
    let id: UUID
    let title: String
    let order: Int
    let duration: String
    let continuesFromPreviousFrame: Bool
    let thumbnail: ThumbnailStyle

    init(
        id: UUID = UUID(),
        title: String,
        order: Int,
        duration: String,
        continuesFromPreviousFrame: Bool,
        thumbnail: ThumbnailStyle
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.duration = duration
        self.continuesFromPreviousFrame = continuesFromPreviousFrame
        self.thumbnail = thumbnail
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let timeAgo: String
    let thumbnail: ThumbnailStyle
}

struct UserProfile {
    let name: String
    let handle: String
    let plan: String
    let monthlyCreditsUsed: Int
    let monthlyCreditsTotal: Int
    let projectCount: Int
    let clipCount: Int
    let exportCount: Int
}

enum ClipStatus {
    case done
    case processing(Int)
    case queued

    var label: String {
        switch self {
        case .done:
            "Done"
        case .processing(let progress):
            "\(progress)%"
        case .queued:
            "Queued"
        }
    }
}

enum ThumbnailStyle {
    case city
    case ocean
    case forest
    case lights
}
