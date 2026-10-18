import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("checklist", "Управляй задачами", "Создавай, редактируй и сортируй задачи. Расставляй приоритеты и не пропускай сроки."),
        ("timer", "Фокусируйся", "Используй Pomodoro-таймер для глубокой работы. Чередуй фокус и отдых."),
        ("chart.bar.fill", "Отслеживай прогресс", "Смотри статистику по задачам, категориям и приоритетам. Будь продуктивнее каждый день.")
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 28) {
                            Image(systemName: page.icon)
                                .font(.system(size: 70))
                                .foregroundStyle(Color.accentColor)
                                .symbolEffect(.bounce, options: .repeating, value: currentPage)

                            VStack(spacing: 12) {
                                Text(page.title)
                                    .font(.title.bold())

                                Text(page.subtitle)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 360)

                Spacer()

                Button {
                    HapticManager.medium()
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasSeenOnboarding = true
                        }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Далее" : "Начать")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}
