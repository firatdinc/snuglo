import SwiftUI

// MARK: — SunCheckBadge
// A friendly "green sun" — a green disc with short rays radiating around it —
// and a white checkmark in the centre. Used to mark the daily puzzle as solved.

struct SunCheckBadge: View {

    var size: CGFloat = 52
    var rayCount: Int = 12

    var body: some View {
        ZStack {
            // Rays
            ForEach(0..<rayCount, id: \.self) { i in
                Capsule()
                    .fill(AppColors.successGreen)
                    .frame(width: size * 0.07, height: size * 0.15)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(i) / Double(rayCount) * 360))
            }

            // Sun body
            Circle()
                .fill(AppColors.successGreen)
                .frame(width: size * 0.66, height: size * 0.66)

            // White check
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.30, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: — Preview

#Preview {
    HStack(spacing: 20) {
        SunCheckBadge(size: 40)
        SunCheckBadge(size: 52)
        SunCheckBadge(size: 72)
    }
    .padding()
    .background(AppColors.background)
}
