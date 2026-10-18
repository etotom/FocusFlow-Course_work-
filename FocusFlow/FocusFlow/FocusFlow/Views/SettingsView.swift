import SwiftUI

enum AppAccentColor: String, CaseIterable {
    case indigo = "Индиго"
    case blue = "Синий"
    case purple = "Фиолетовый"
    case mint = "Мятный"
    case teal = "Бирюзовый"
    case pink = "Розовый"
    case orange = "Оранжевый"
    case red = "Красный"

    var color: Color {
        switch self {
        case .indigo: return .indigo
        case .blue:   return .blue
        case .purple: return .purple
        case .mint:   return .mint
        case .teal:   return .teal
        case .pink:   return .pink
        case .orange: return .orange
        case .red:    return .red
        }
    }

    var uiColor: UIColor {
        UIColor(color)
    }
}

struct SettingsView: View {
    @AppStorage("accentColor") private var accentColorRaw: String = AppAccentColor.indigo.rawValue
    @Environment(\.dismiss) private var dismiss

    private var selectedColor: AppAccentColor {
        AppAccentColor(rawValue: accentColorRaw) ?? .indigo
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    accentColorSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    // MARK: - Accent Color

    private var accentColorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Акцентный цвет")

            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AppAccentColor.allCases, id: \.rawValue) { accent in
                    let isSelected = accent == selectedColor
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            accentColorRaw = accent.rawValue
                        }
                        HapticManager.light()
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(accent.color)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .shadow(color: accent.color.opacity(0.3), radius: isSelected ? 8 : 0, y: 2)
                                .scaleEffect(isSelected ? 1.1 : 1.0)

                            Text(accent.rawValue)
                                .font(.caption2)
                                .foregroundStyle(isSelected ? accent.color : .secondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("О приложении")

            VStack(spacing: 0) {
                aboutRow(icon: "sparkles", label: "Приложение", value: "FocusFlow")
                Divider().padding(.leading, 36)
                aboutRow(icon: "tag", label: "Версия", value: "1.0")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func aboutRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

#Preview {
    SettingsView()
}
