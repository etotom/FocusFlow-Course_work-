import SwiftUI

struct PulsingButton: View {
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.accentColor.opacity(0.4), radius: isPulsing ? 14 : 8, x: 0, y: 4)
                .scaleEffect(isPulsing ? 1.06 : 1.0)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}
