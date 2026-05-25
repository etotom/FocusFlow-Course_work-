import SwiftUI

struct TaskCardView: View {
    let task: Task
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var checkScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 0) {
            // Цветная полоска приоритета
            RoundedRectangle(cornerRadius: 3)
                .fill(task.priority.color)
                .frame(width: 5)
                .padding(.vertical, 10)

            HStack(spacing: 12) {
                // Кнопка выполнения
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        checkScale = 1.4
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            checkScale = 1.0
                        }
                    }
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

                // Содержимое задачи
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

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Label(task.priority.title, systemImage: task.priority.icon)
                            .font(.caption2)
                            .foregroundStyle(task.priority.color)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taskCard")
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onDelete()
                }
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}
