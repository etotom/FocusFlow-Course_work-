import SwiftUI

private enum TimerMode: CaseIterable, Equatable {
    case focus, shortBreak, longBreak

    var duration: TimeInterval {
        switch self {
        case .focus:      return 25 * 60
        case .shortBreak: return  5 * 60
        case .longBreak:  return 15 * 60
        }
    }

    var label: String {
        switch self {
        case .focus:      return "Фокус"
        case .shortBreak: return "Перерыв"
        case .longBreak:  return "Отдых"
        }
    }

    var fullLabel: String {
        switch self {
        case .focus:      return "Время фокуса"
        case .shortBreak: return "Короткий перерыв"
        case .longBreak:  return "Длинный перерыв"
        }
    }

    var color: Color {
        switch self {
        case .focus:      return .indigo
        case .shortBreak: return .teal
        case .longBreak:  return .mint
        }
    }

    var icon: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak:  return "figure.walk"
        }
    }
}

struct FocusTimerView: View {
    @State private var mode: TimerMode = .focus
    @State private var timeRemaining: TimeInterval = TimerMode.focus.duration
    @State private var isRunning = false
    @State private var sessionCount = 0
    @State private var countdown: Foundation.Timer? = nil

    private var progress: Double {
        1.0 - timeRemaining / mode.duration
    }

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header.padding(.bottom, 36)
                    timerRing.padding(.bottom, 44)
                    controls.padding(.bottom, 32)
                    modePicker.padding(.bottom, 32)
                    sessionsRow
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [mode.color.opacity(0.14), Color(.systemGroupedBackground), Color(.systemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: mode)

            Circle()
                .fill(mode.color.opacity(0.06))
                .frame(width: 320, height: 320)
                .offset(y: -60)
                .scaleEffect(isRunning ? 1.12 : 0.95)
                .opacity(isRunning ? 1 : 0)
                .animation(
                    isRunning
                        ? .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
                        : .easeInOut(duration: 0.4),
                    value: isRunning
                )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Pomodoro")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Таймер")
                    .font(.largeTitle.bold())
            }
            Spacer()
            Image(systemName: mode.icon)
                .font(.title)
                .foregroundStyle(mode.color)
                .animation(.spring(response: 0.4, dampingFraction: 0.65), value: mode)
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 20)
                .frame(width: 230, height: 230)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [mode.color.opacity(0.5), mode.color, mode.color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 230, height: 230)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            if progress > 0.01 {
                Circle()
                    .fill(mode.color)
                    .frame(width: 16, height: 16)
                    .shadow(color: mode.color.opacity(0.6), radius: 6)
                    .offset(y: -115)
                    .rotationEffect(.degrees(progress * 360))
                    .animation(.linear(duration: 1), value: progress)
            }

            VStack(spacing: 6) {
                Text(timeString)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .contentTransition(.numericText(countsDown: true))

                Text(mode.fullLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(mode.color)
                    .animation(.easeInOut(duration: 0.3), value: mode)
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 20) {
            circleButton(icon: "arrow.counterclockwise", color: .secondary) { resetTimer() }

            Button { toggleTimer() } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [mode.color, mode.color.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 78, height: 78)
                        .shadow(color: mode.color.opacity(0.45), radius: 16, y: 6)
                        .animation(.easeInOut(duration: 0.4), value: mode)

                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(.plain)

            circleButton(icon: "forward.end.fill", color: .secondary) { skip() }
        }
    }

    @ViewBuilder
    private func circleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 58, height: 58)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimerMode.allCases, id: \.label) { m in
                Button {
                    guard m != mode else { return }
                    HapticManager.selection()
                    switchMode(to: m)
                } label: {
                    Text(m.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(mode == m ? m.color : Color(.secondarySystemBackground))
                        .foregroundStyle(mode == m ? .white : .secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mode)
            }
        }
    }

    // MARK: - Sessions Row

    private var sessionsRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i < (sessionCount % 4) ? Color.accentColor : Color(.tertiarySystemFill))
                        .frame(width: 32, height: 8)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.05),
                            value: sessionCount
                        )
                }
            }
            Label("Выполнено сессий: \(sessionCount)", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var timeString: String {
        String(format: "%02d:%02d", Int(timeRemaining) / 60, Int(timeRemaining) % 60)
    }

    // MARK: - Timer Actions

    private func toggleTimer() {
        isRunning.toggle()
        HapticManager.medium()
        if isRunning {
            countdown = Foundation.Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                withAnimation {
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        handleFinish()
                    }
                }
            }
        } else {
            countdown?.invalidate()
            countdown = nil
        }
    }

    private func resetTimer() {
        isRunning = false
        countdown?.invalidate()
        countdown = nil
        HapticManager.light()
        withAnimation { timeRemaining = mode.duration }
    }

    private func skip() {
        isRunning = false
        countdown?.invalidate()
        countdown = nil
        HapticManager.light()
        handleFinish()
    }

    private func handleFinish() {
        isRunning = false
        countdown?.invalidate()
        countdown = nil
        HapticManager.playTimerCompleteSound()
        HapticManager.success()
        if mode == .focus {
            sessionCount += 1
            switchMode(to: sessionCount % 4 == 0 ? .longBreak : .shortBreak)
        } else {
            switchMode(to: .focus)
        }
    }

    private func switchMode(to newMode: TimerMode) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { mode = newMode }
        timeRemaining = newMode.duration
    }
}

#Preview { FocusTimerView() }
