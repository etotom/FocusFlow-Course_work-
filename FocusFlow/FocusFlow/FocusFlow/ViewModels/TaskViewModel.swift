import Foundation
import Combine
import SwiftUI

final class TaskViewModel: ObservableObject {

    @Published private(set) var tasks: [Task] = []

    private let storageKey = "focusflow.tasks"

    init() {
        load()
    }

    // MARK: - Public API

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
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        save()
    }

    func update(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Task].self, from: data)
        else { return }
        tasks = decoded
    }
}
