import SwiftUI

struct TaskCardView: View {
    let task: Task
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: (() -> Void)?

    @State private var checkScale: CGFloat = 1.0

    init(task: Task, onToggle: @escaping () -> Void, onDelete: @escaping () -> Void, onEdit: (() -> Void)? = nil) {
        self.task = task
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.onEdit = onEdit
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(task.isOverdue ? Color.red : task.priority.color)
                .frame(width: 5)
                .padding(.vertical, 10)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { checkScale = 1.4 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { checkScale = 1.0 }
                    }
                    HapticManager.medium()
                    onToggle()
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(task.isCompleted ? task.priority.color : .secondary)
                        .scaleEffect(checkScale)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("toggleComplete")
                .accessibilityValue(task.isCompleted ? "completed" : "pending")

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .strikethrough(task.isCompleted, color: .secondary)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)

                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Label(task.category.title, systemImage: task.category.icon)
                            .font(.caption2)
                            .foregroundStyle(task.category.color)

                        Text("•").font(.caption2).foregroundStyle(.tertiary)

                        Label(task.priority.title, systemImage: task.priority.icon)
                            .font(.caption2)
                            .foregroundStyle(task.priority.color)

                        if let due = task.dueDate {
                            Text("•").font(.caption2).foregroundStyle(.tertiary)
                            Label(
                                dueDateLabel(due),
                                systemImage: task.isOverdue
                                    ? "exclamationmark.circle.fill"
                                    : (task.isDueSoon ? "clock.fill" : "calendar")
                            )
                            .font(.caption2.weight(task.isOverdue ? .semibold : .regular))
                            .foregroundStyle(task.isOverdue ? .red : (task.isDueSoon ? .orange : .secondary))
                        }
                    }
                }

                Spacer(minLength: 0)

                if task.isOverdue {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(task.isOverdue ? Color.red.opacity(0.04) : Color.clear)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: task.isOverdue ? Color.red.opacity(0.14) : .black.opacity(0.07),
            radius: 8, x: 0, y: 3
        )
        .onTapGesture {
            HapticManager.light()
            onEdit?()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taskCard")
        .contextMenu {
            if let onEdit {
                Button {
                    HapticManager.light()
                    onEdit()
                } label: {
                    Label("Редактировать", systemImage: "pencil")
                }
            }
            Divider()
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) { onDelete() }
                HapticManager.warning()
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private func dueDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Сегодня" }
        if cal.isDateInTomorrow(date)  { return "Завтра" }
        if cal.isDateInYesterday(date) { return "Вчера" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "d MMM"
        return fmt.string(from: date)
    }
}
