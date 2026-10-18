import Foundation
import Combine
import SwiftUI

enum SortOption: String, CaseIterable {
    case dateAdded = "Дата добавления"
    case priority  = "Приоритет"
    case dueDate   = "По сроку"
    case title     = "По названию"
}

final class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [Task] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Category? = nil
    @Published var sortOption: SortOption = .dateAdded
    @Published var showCompleted: Bool = true

    private let storageKey = "focusflow.tasks"

    init() { load() }

    // MARK: - Filtered & Sorted

    var filteredTasks: [Task] {
        var result = tasks

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !showCompleted {
            result = result.filter { !$0.isCompleted }
        }

        switch sortOption {
        case .dateAdded:
            result.sort { $0.createdAt > $1.createdAt }
        case .priority:
            let order: [Priority] = [.high, .medium, .low]
            result.sort {
                (order.firstIndex(of: $0.priority) ?? 0) < (order.firstIndex(of: $1.priority) ?? 0)
            }
        case .dueDate:
            result.sort {
                switch ($0.dueDate, $1.dueDate) {
                case (let a?, let b?): return a < b
                case (_?, nil):        return true
                case (nil, _?):        return false
                default:               return $0.createdAt > $1.createdAt
                }
            }
        case .title:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        }

        return result
    }

    var pendingCount:   Int { tasks.filter { !$0.isCompleted }.count }
    var completedCount: Int { tasks.filter {  $0.isCompleted }.count }
    var overdueCount:   Int { tasks.filter {  $0.isOverdue   }.count }

    var priorityCounts: [Priority: Int] {
        Dictionary(uniqueKeysWithValues: Priority.allCases.map { p in
            (p, tasks.filter { $0.priority == p }.count)
        })
    }

    // MARK: - CRUD

    func add(_ task: Task) {
        tasks.insert(task, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        save()
    }

    func delete(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func toggleComplete(_ task: Task) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[i].isCompleted.toggle()
        save()
    }

    func update(_ task: Task) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[i] = task
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Task].self, from: data)
        else { return }
        tasks = decoded
    }
}
