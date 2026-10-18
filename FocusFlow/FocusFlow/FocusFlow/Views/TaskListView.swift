import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var appearedIDs: Set<UUID> = []
    @State private var editingTask: Task? = nil
    @State private var showSettings = false

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                headerView
                searchFilterBar
                if viewModel.filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
        }
        .sheet(item: $editingTask) { task in
            AddTaskView(viewModel: viewModel, editingTask: task)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
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
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("FocusFlow")
                    .font(.largeTitle.bold())

                HStack(spacing: 8) {
                    Text(pendingLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if viewModel.overdueCount > 0 {
                        Label("\(viewModel.overdueCount) просрочено", systemImage: "exclamationmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 12) {
                    Button {
                        HapticManager.light()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    Text(todayDateString)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Image(systemName: "checkmark.seal.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Search & Filter Bar

    private var searchFilterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    TextField("Поиск задач...", text: $viewModel.searchText)
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                let isFiltered = viewModel.sortOption != .dateAdded || !viewModel.showCompleted
                Menu {
                    Section("Сортировка") {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                HapticManager.selection()
                                withAnimation { viewModel.sortOption = option }
                            } label: {
                                if viewModel.sortOption == option {
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        HapticManager.selection()
                        withAnimation { viewModel.showCompleted.toggle() }
                    } label: {
                        Label(
                            viewModel.showCompleted ? "Скрыть выполненные" : "Показать выполненные",
                            systemImage: viewModel.showCompleted ? "eye.slash" : "eye"
                        )
                    }
                } label: {
                    Image(systemName: isFiltered
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundStyle(isFiltered ? Color.accentColor : .secondary)
                        .frame(width: 42, height: 38)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "Все",
                        icon: "square.grid.2x2.fill",
                        color: .accentColor,
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedCategory = nil
                        }
                    }
                    ForEach(Category.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.title,
                            icon: category.icon,
                            color: category.color,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedCategory =
                                    viewModel.selectedCategory == category ? nil : category
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredTasks.enumerated()), id: \.element.id) { index, task in
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
                        },
                        onEdit: { editingTask = task }
                    )
                    .padding(.horizontal, 16)
                    .opacity(appearedIDs.contains(task.id) ? 1 : 0)
                    .offset(y: appearedIDs.contains(task.id) ? 0 : 24)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.35).delay(Double(index) * 0.06)) {
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

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            let isFiltered = !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil
            Image(systemName: isFiltered ? "magnifyingglass" : "tray")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
            Text(isFiltered ? "Ничего не найдено" : "Нет задач")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text(isFiltered
                 ? "Попробуйте изменить фильтры"
                 : "Нажмите «+» внизу, чтобы добавить")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Computed Strings

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Доброе утро"
        case 12..<18: return "Добрый день"
        case 18..<23: return "Добрый вечер"
        default:      return "Доброй ночи"
        }
    }

    private var pendingLabel: String {
        switch viewModel.pendingCount {
        case 0:  return "Все задачи выполнены"
        case 1:  return "1 задача ожидает"
        default: return "\(viewModel.pendingCount) задач ожидают"
        }
    }

    private var todayDateString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "d MMMM"
        return fmt.string(from: Date())
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2.weight(.semibold))
                Text(title).font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? color : Color(.separator), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
