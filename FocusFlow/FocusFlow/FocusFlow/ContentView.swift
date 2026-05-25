import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var selectedTab = 0
    @State private var prevTab = 0
    @State private var showAddTask = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Контент с отступом под таббар
            Group {
                if selectedTab == 0 {
                    TaskListView(viewModel: viewModel)
                        .transition(slideTransition)
                } else {
                    StatsView(viewModel: viewModel)
                        .transition(slideTransition)
                }
            }
            .animation(.easeInOut(duration: 0.28), value: selectedTab)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 62)
            }

            // Кастомный таббар
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddTask) {
            AddTaskView(viewModel: viewModel)
        }
    }

    // MARK: - Slide Transition

    private var slideTransition: AnyTransition {
        let forward = selectedTab > prevTab
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        ZStack(alignment: .top) {
            // Frosted background, уходит за нижний край экрана
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)

            Divider()

            HStack(spacing: 0) {
                tabItem(icon: "checklist", label: "Задачи", tag: 0)

                Spacer()

                // Центральная кнопка «+» — приподнята над баром
                centerButton
                    .offset(y: -18)

                Spacer()

                tabItem(icon: "chart.bar.fill", label: "Статистика", tag: 1)
            }
            .padding(.horizontal, 36)
            .frame(height: 62)
        }
        .frame(height: 62)
    }

    private var centerButton: some View {
        Button { showAddTask = true } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color(red: 0.55, green: 0.15, blue: 0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.accentColor.opacity(0.45), radius: 12, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
        }
        .accessibilityIdentifier("addTaskButton")
    }

    @ViewBuilder
    private func tabItem(icon: String, label: String, tag: Int) -> some View {
        let active = selectedTab == tag
        Button {
            guard selectedTab != tag else { return }
            prevTab = selectedTab
            withAnimation(.easeInOut(duration: 0.28)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? Color.accentColor : .secondary)
                    .scaleEffect(active ? 1.1 : 1.0)
                Text(label)
                    .font(.system(size: 10, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? Color.accentColor : .secondary)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: active)
        }
        .buttonStyle(.plain)
        .frame(width: 80)
    }
}

#Preview {
    ContentView()
}
