import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: TaskViewModel

    @State private var tiltAngle: Double = 0
    @State private var animatedProgress: Double = 0
    @State private var animatedTotal: Double = 0
    @State private var animatedCompleted: Double = 0
    @State private var animatedPending: Double = 0
    @State private var animatedCounts: [String: Double] = [:]
    @State private var barsVisible = false
    @State private var hasAnimated = false

    private var total: Int { viewModel.tasks.count }
    private var completed: Int { viewModel.tasks.filter { $0.isCompleted }.count }
    private var pending: Int { total - completed }
    private var progress: Double { total > 0 ? Double(completed) / Double(total) : 0 }

    private func categoryCount(_ category: Category) -> Int {
        viewModel.tasks.filter { $0.category == category }.count
    }

    private var maxCategoryCount: Int {
        Category.allCases.map { categoryCount($0) }.max() ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ringSection
                        .padding(.top, 8)
                    summarySection
                    categorySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
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
            )
            .navigationTitle("Статистика")
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                startAnimations()
            }
        }
    }

    // MARK: - 3D Ring

    private var ringSection: some View {
        ZStack {
            // Трек
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 22)
                .frame(width: 210, height: 210)

            // Прогресс
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

            // Центр
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
        // 3D-эффект: кольцо слегка наклоняется и «дышит»
        .rotation3DEffect(
            .degrees(tiltAngle),
            axis: (x: 1.0, y: 0.3, z: 0.0),
            perspective: 0.45
        )
    }

    // MARK: - Summary Cards

    private var summarySection: some View {
        HStack(spacing: 12) {
            StatCard(label: "Всего",      value: animatedTotal,     color: .blue)
            StatCard(label: "Выполнено",  value: animatedCompleted, color: .green)
            StatCard(label: "Осталось",   value: animatedPending,   color: .orange)
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
                        ? CGFloat(count) / CGFloat(maxCategoryCount)
                        : 0
                    let barDelay = 0.45 + Double(index) * 0.12

                    VStack(spacing: 6) {
                        AnimatableNumber(number: animatedCounts[category.rawValue] ?? 0)
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(category.color)

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(category.color.opacity(0.12))
                                .frame(height: 130)

                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [category.color.opacity(0.65), category.color],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: barsVisible ? max(8, 130 * ratio) : 0)
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

    // MARK: - Start Animations

    private func startAnimations() {
        // Кольцо прогресса
        withAnimation(.easeOut(duration: 1.2)) {
            animatedProgress = progress
        }
        // Счётчики сводки
        withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
            animatedTotal     = Double(total)
            animatedCompleted = Double(completed)
            animatedPending   = Double(pending)
        }
        // 3D-покачивание — бесконечное
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            tiltAngle = 16
        }
        // Бары вырастают
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            barsVisible = true
        }
        // Счётчики баров (каскадом)
        for (index, category) in Category.allCases.enumerated() {
            withAnimation(.easeOut(duration: 0.9).delay(0.5 + Double(index) * 0.12)) {
                animatedCounts[category.rawValue] = Double(categoryCount(category))
            }
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
