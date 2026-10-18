import SwiftUI

struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    let editingTask: Task?

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedPriority: Priority = .medium
    @State private var selectedCategory: Category = .personal
    @State private var hasDueDate = false
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    @State private var titleIsInvalid = false
    @State private var shakeOffset: CGFloat = 0
    @State private var saveScale: CGFloat = 1.0

    init(viewModel: TaskViewModel, editingTask: Task? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.editingTask = editingTask
        if let task = editingTask {
            _title = .init(initialValue: task.title)
            _notes = .init(initialValue: task.notes)
            _selectedPriority = .init(initialValue: task.priority)
            _selectedCategory = .init(initialValue: task.category)
            _hasDueDate = .init(initialValue: task.dueDate != nil)
            _dueDate = .init(initialValue: task.dueDate ?? Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    titleSection
                    notesSection
                    dueDateSection
                    prioritySection
                    categorySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(editingTask != nil ? "Редактировать" : "Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Название")
            TextField("Что нужно сделать?", text: $title)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(titleIsInvalid ? Color.red : Color.clear, lineWidth: 1.5)
                )
                .offset(x: shakeOffset)
                .onChange(of: title) { if titleIsInvalid { titleIsInvalid = false } }
                .accessibilityIdentifier("titleField")
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Заметки")
            TextField("Дополнительные детали...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("notesField")
        }
    }

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Срок выполнения")

            VStack(spacing: 0) {
                Toggle(isOn: $hasDueDate.animation(.spring(response: 0.3, dampingFraction: 0.7))) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.accentColor)
                        Text("Установить срок")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .padding(14)

                if hasDueDate {
                    Divider().padding(.leading, 14)
                    DatePicker(
                        "Дата",
                        selection: $dueDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Приоритет")
            HStack(spacing: 10) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    PriorityButton(priority: priority, isSelected: selectedPriority == priority) {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedPriority = priority
                        }
                    }
                    .accessibilityIdentifier("priority.\(priority.rawValue)")
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Категория")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Category.allCases, id: \.self) { category in
                        CategoryChip(category: category, isSelected: selectedCategory == category) {
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedCategory = category
                            }
                        }
                        .accessibilityIdentifier("category.\(category.rawValue)")
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button { handleSave() } label: {
            Text("Сохранить")
                .fontWeight(.semibold)
                .scaleEffect(saveScale)
        }
        .accessibilityIdentifier("saveButton")
    }

    // MARK: - Actions

    private func handleSave() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            HapticManager.warning()
            triggerShake()
            return
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { saveScale = 0.85 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { saveScale = 1.0 }
        }

        if let existingTask = editingTask {
            let updated = Task(
                id: existingTask.id,
                title: title.trimmingCharacters(in: .whitespaces),
                notes: notes.trimmingCharacters(in: .whitespaces),
                priority: selectedPriority,
                category: selectedCategory,
                isCompleted: existingTask.isCompleted,
                createdAt: existingTask.createdAt,
                dueDate: hasDueDate ? dueDate : nil
            )
            viewModel.update(updated)
            HapticManager.success()
        } else {
            let task = Task(
                title: title.trimmingCharacters(in: .whitespaces),
                notes: notes.trimmingCharacters(in: .whitespaces),
                priority: selectedPriority,
                category: selectedCategory,
                dueDate: hasDueDate ? dueDate : nil
            )
            viewModel.add(task)
            HapticManager.light()
        }
        dismiss()
    }

    private func triggerShake() {
        titleIsInvalid = true
        let duration = 0.06
        let offsets: [CGFloat] = [10, -10, 8, -8, 5, -5, 0]
        var delay = 0.0
        for offset in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: duration)) { shakeOffset = offset }
            }
            delay += duration
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Priority Button

private struct PriorityButton: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: priority.icon).font(.caption.weight(.semibold))
                Text(priority.title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? priority.color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? priority.color : Color(.separator), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon).font(.caption.weight(.semibold))
                Text(category.title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? category.color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? category.color : Color(.separator), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
