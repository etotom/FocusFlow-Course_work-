import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var appearedIDs: Set<UUID> = []

    private var pendingCount: Int {
        viewModel.tasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.09),
                    Color(.systemGroupedBackground),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                if viewModel.tasks.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FocusFlow")
                    .font(.largeTitle.bold())
                Text(pendingCountLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var pendingCountLabel: String {
        switch pendingCount {
        case 0: return "Все задачи выполнены"
        case 1: return "1 задача ожидает"
        default: return "\(pendingCount) задачи ожидают"
        }
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                    TaskCardView(
                        task: task,
                        onToggle: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.toggleComplete(task)
                            }
                        },
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.delete(task)
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .opacity(appearedIDs.contains(task.id) ? 1 : 0)
                    .offset(y: appearedIDs.contains(task.id) ? 0 : 24)
                    .onAppear {
                        let delay = Double(index) * 0.06
                        withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                            _ = appearedIDs.insert(task.id)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.delete(task)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        .accessibilityIdentifier("deleteButton")
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            Text("Нет задач")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Нажмите «+» внизу, чтобы добавить")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}
