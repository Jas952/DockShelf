import Foundation

struct ShelfApp: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var path: String
    var bundleIdentifier: String?

    init(id: UUID = UUID(), name: String, path: String, bundleIdentifier: String? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.bundleIdentifier = bundleIdentifier ?? Bundle(url: URL(fileURLWithPath: path))?.bundleIdentifier
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case path
        case bundleIdentifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
            ?? Bundle(url: URL(fileURLWithPath: path))?.bundleIdentifier
    }
}

struct ShelfGroup: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var xPosition: Double
    var width: Double
    var opacity: Double
    var borderWidth: Double
    var cornerRadius: Double
    var imagePath: String?
    var showsImage: Bool
    var iconSlots: Int
    var apps: [ShelfApp]

    init(
        id: UUID = UUID(),
        title: String,
        xPosition: Double,
        width: Double = 180,
        opacity: Double = 0.34,
        borderWidth: Double = 2,
        cornerRadius: Double = 14,
        imagePath: String? = nil,
        showsImage: Bool = true,
        iconSlots: Int = 3,
        apps: [ShelfApp] = []
    ) {
        self.id = id
        self.title = title
        self.xPosition = xPosition
        self.width = width
        self.opacity = opacity
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.imagePath = imagePath
        self.showsImage = showsImage
        self.iconSlots = iconSlots
        self.apps = apps
    }

    static let sampleData: [ShelfGroup] = [
        ShelfGroup(title: "Работа", xPosition: 390, width: 220, iconSlots: 4),
        ShelfGroup(title: "Дизайн", xPosition: 630, width: 190, iconSlots: 3)
    ]
}

extension ShelfGroup {
    var effectiveIconSlots: Int {
        max(iconSlots, apps.count, 1)
    }

    var fittedWidth: Double {
        let appArea = Double(effectiveIconSlots) * 35 + Double(max(effectiveIconSlots - 1, 0)) * 7
        let imageArea = imagePath == nil || !showsImage ? 0 : 44
        return max(112, appArea + Double(imageArea) + 44)
    }

    mutating func fitWidthToApps() {
        width = min(max(fittedWidth, 88), 560)
        iconSlots = min(max(apps.count, 1), 8)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case xPosition
        case width
        case opacity
        case borderWidth
        case cornerRadius
        case imagePath
        case showsImage
        case iconSlots
        case apps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        xPosition = try container.decode(Double.self, forKey: .xPosition)
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 180
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 0.34
        borderWidth = try container.decodeIfPresent(Double.self, forKey: .borderWidth) ?? 2
        cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 14
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        showsImage = try container.decodeIfPresent(Bool.self, forKey: .showsImage) ?? true
        iconSlots = try container.decodeIfPresent(Int.self, forKey: .iconSlots) ?? 3
        apps = try container.decodeIfPresent([ShelfApp].self, forKey: .apps) ?? []
    }
}
