import SwiftUI

struct Task: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var notes: String
    var priority: Priority
    var category: Category
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        priority: Priority = .medium,
        category: Category = .personal,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

enum Priority: String, Codable, CaseIterable {
    case low
    case medium
    case high

    var title: String {
        switch self {
        case .low:    return "Низкий"
        case .medium: return "Средний"
        case .high:   return "Высокий"
        }
    }

    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }

    var icon: String {
        switch self {
        case .low:    return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high:   return "arrow.up.circle"
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case work
    case personal
    case study
    case health

    var title: String {
        switch self {
        case .work:     return "Работа"
        case .personal: return "Личное"
        case .study:    return "Учёба"
        case .health:   return "Здоровье"
        }
    }

    var color: Color {
        switch self {
        case .work:     return .blue
        case .personal: return .purple
        case .study:    return .indigo
        case .health:   return .mint
        }
    }

    var icon: String {
        switch self {
        case .work:     return "briefcase"
        case .personal: return "person"
        case .study:    return "book"
        case .health:   return "heart"
        }
    }
}
