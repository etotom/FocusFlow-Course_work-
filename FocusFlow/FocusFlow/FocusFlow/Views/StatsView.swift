import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: TaskViewModel

    @State private var tiltAngle: Double = 0
    @State private var animatedProgress: Double = 0
    @State private var animatedTotal: Double = 0
    @State private var animatedCompleted: Double = 0
    @State private var animatedPending: Double = 0
    @State private var animatedCounts: [String: Double] = [:]
    @State private var animatedPriorityCounts: [String: Double] = [:]
    @State private var barsVisible = false
    @State private var priorityBarsVisible = false
    @State private var hasAnimated = false

    private var total: Int     { viewModel.tasks.count }
    private var completed: Int { viewModel.tasks.filter { $0.isCompleted }.count }
    private var pending: Int   { total - completed }
    private var overdue: Int   { viewModel.overdueCount }
    private var progress: Double { total > 0 ? Double(completed) / Double(total) : 0 }

    private func categoryCount(_ category: Category) -> Int {
        viewModel.tasks.filter { $0.category == category }.count
    }

    private var maxCategoryCount: Int {
        Category.allCases.map { categoryCount($0) }.max() ?? 1
    }

    private func priorityCount(_ priority: Priority) -> Int {
        viewModel.tasks.filter { $0.priority == priority }.count
    }

    private var maxPriorityCount: Int {
        Priority.allCases.map { priorityCount($0) }.max() ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    if overdue > 0 {
                        overdueAlert
                    }
                    ringSection.padding(.top, 8)
                    summarySection
                    categorySection
                    prioritySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.09), Color(.systemGroupedBackground), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Статистика")
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                startAnimations()
            }
            .onChange(of: viewModel.tasks.count) {
                restartAnimations()
            }
        }
    }

    // MARK: - Overdue Alert

    private var overdueAlert: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text("Просроченные задачи")
                    .font(.subheadline.weight(.semibold))
                Text("\(overdue) задач пропустили срок")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(overdue)")
                .font(.title2.bold())
                .foregroundStyle(.red)
        }
        .padding(14)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Ring

    private var ringSection: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 22)
                .frame(width: 210, height: 210)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [.blue, .purple, .pink, .blue],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.2), value: animatedProgress)

            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    AnimatableNumber(number: animatedProgress * 100)
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.title.bold())
                        .foregroundStyle(.secondary)
                }
                Text("выполнено")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .rotation3DEffect(
            .degrees(tiltAngle),
            axis: (x: 1.0, y: 0.3, z: 0.0),
            perspective: 0.45
        )
    }

    // MARK: - Summary Cards

    private var summarySection: some View {
        HStack(spacing: 12) {
            StatCard(label: "Всего",     value: animatedTotal,     color: .blue)
            StatCard(label: "Выполнено", value: animatedCompleted, color: .green)
            StatCard(label: "Осталось",  value: animatedPending,   color: .orange)
        }
    }

    // MARK: - Category Bars

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("По категориям")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(Category.allCases.enumerated()), id: \.element) { index, category in
                    let count = categoryCount(category)
                    let ratio: CGFloat = maxCategoryCount > 0
                        ? CGFloat(count) / CGFloat(maxCategoryCount) : 0
                    let barDelay = 0.45 + Double(index) * 0.12

                    VStack(spacing: 6) {
                        AnimatableNumber(number: animatedCounts[category.rawValue] ?? 0)
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(category.color)

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(category.color.opacity(0.12))
                                .frame(height: 120)

                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [category.color.opacity(0.65), category.color],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: barsVisible ? max(8, 120 * ratio) : 0)
                                .animation(
                                    .spring(response: 0.7, dampingFraction: 0.65).delay(barDelay),
                                    value: barsVisible
                                )
                        }

                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(category.color)
                        Text(category.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Priority Section

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("По приоритету")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(Array(Priority.allCases.reversed().enumerated()), id: \.element) { index, priority in
                    let count = priorityCount(priority)
                    let ratio: Double = maxPriorityCount > 0
                        ? Double(count) / Double(maxPriorityCount) : 0
                    let animatedRatio = priorityBarsVisible ? ratio : 0
                    let delay = 0.3 + Double(index) * 0.1

                    HStack(spacing: 12) {
                        HStack(spacing: 5) {
                            Image(systemName: priority.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(priority.color)
                            Text(priority.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 88, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(priority.color.opacity(0.12))
                                    .frame(height: 10)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [priority.color.opacity(0.7), priority.color],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: max(0, geo.size.width * animatedRatio),
                                        height: 10
                                    )
                                    .animation(
                                        .spring(response: 0.7, dampingFraction: 0.65).delay(delay),
                                        value: priorityBarsVisible
                                    )
                            }
                        }
                        .frame(height: 10)

                        Text("\(count)")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(priority.color)
                            .frame(width: 22, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeOut(duration: 1.2)) {
            animatedProgress = progress
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
            animatedTotal     = Double(total)
            animatedCompleted = Double(completed)
            animatedPending   = Double(pending)
        }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            tiltAngle = 16
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            barsVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            priorityBarsVisible = true
        }
        for (index, category) in Category.allCases.enumerated() {
            withAnimation(.easeOut(duration: 0.9).delay(0.5 + Double(index) * 0.12)) {
                animatedCounts[category.rawValue] = Double(categoryCount(category))
            }
        }
        for priority in Priority.allCases {
            withAnimation(.easeOut(duration: 0.9).delay(0.6)) {
                animatedPriorityCounts[priority.rawValue] = Double(priorityCount(priority))
            }
        }
    }

    private func restartAnimations() {
        animatedProgress = 0
        animatedTotal = 0; animatedCompleted = 0; animatedPending = 0
        barsVisible = false; priorityBarsVisible = false
        animatedCounts = [:]; animatedPriorityCounts = [:]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startAnimations()
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            AnimatableNumber(number: value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Animatable Counter

private struct AnimatableNumber: View, Animatable {
    var number: Double

    var animatableData: Double {
        get { number }
        set { number = newValue }
    }

    var body: some View {
        Text("\(Int(number))")
    }
}
