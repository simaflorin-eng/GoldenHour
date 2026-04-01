import SwiftUI

enum AppIconVariant: CaseIterable {
    case light
    case dark
}

struct AppIconView: View {
    var size: CGFloat = 200
    var variant: AppIconVariant = .dark

    private var backgroundGradient: LinearGradient {
        switch variant {
        case .light:
            return LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.99, blue: 1.0),
                    Color(red: 0.74, green: 0.82, blue: 0.96),
                    Color(red: 0.18, green: 0.24, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.14),
                    Color(red: 0.12, green: 0.17, blue: 0.31),
                    Color(red: 0.34, green: 0.18, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var glowColor: Color {
        switch variant {
        case .light:
            return Color(red: 1.0, green: 0.78, blue: 0.4)
        case .dark:
            return Color(red: 1.0, green: 0.67, blue: 0.25)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient

            Circle()
                .fill(.white.opacity(variant == .light ? 0.18 : 0.1))
                .frame(width: size * 0.84, height: size * 0.84)
                .blur(radius: size * 0.015)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(variant == .light ? 0.32 : 0.14),
                            .white.opacity(0.03),
                            .clear
                        ],
                        center: .topLeading,
                        startRadius: size * 0.04,
                        endRadius: size * 0.42
                    )
                )
                .frame(width: size * 0.84, height: size * 0.84)
                .offset(x: -size * 0.06, y: -size * 0.08)

            Circle()
                .strokeBorder(.white.opacity(variant == .light ? 0.32 : 0.16), lineWidth: size * 0.015)
                .background(
                    Circle()
                        .fill(.white.opacity(variant == .light ? 0.09 : 0.05))
                )
                .frame(width: size * 0.74, height: size * 0.74)
                .overlay {
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    .white.opacity(0.0),
                                    .white.opacity(variant == .light ? 0.7 : 0.4),
                                    glowColor.opacity(0.6),
                                    .white.opacity(0.0)
                                ],
                                center: .center,
                                angle: .degrees(-95)
                            ),
                            lineWidth: size * 0.02
                        )
                        .padding(size * 0.06)
                }
                .shadow(color: .black.opacity(variant == .light ? 0.12 : 0.28), radius: size * 0.05, y: size * 0.03)

            Circle()
                .trim(from: 0.1, to: 0.43)
                .stroke(
                    glowColor.opacity(0.95),
                    style: StrokeStyle(lineWidth: size * 0.038, lineCap: .round)
                )
                .frame(width: size * 0.46, height: size * 0.46)
                .rotationEffect(.degrees(112))
                .shadow(color: glowColor.opacity(0.45), radius: size * 0.045)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.98),
                            Color(red: 0.96, green: 0.46, blue: 0.16).opacity(0.9),
                            .clear
                        ],
                        center: .center,
                        startRadius: size * 0.01,
                        endRadius: size * 0.19
                    )
                )
                .frame(width: size * 0.28, height: size * 0.28)
                .offset(y: size * 0.085)
                .blur(radius: size * 0.004)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(variant == .light ? 0.68 : 0.28),
                            .white.opacity(variant == .light ? 0.22 : 0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.42, height: size * 0.042)
                .offset(y: size * 0.17)
                .shadow(color: .black.opacity(variant == .light ? 0.1 : 0.22), radius: size * 0.03, y: size * 0.014)

            Circle()
                .fill(.white.opacity(variant == .light ? 0.95 : 0.88))
                .frame(width: size * 0.055, height: size * 0.055)
                .overlay {
                    Circle()
                        .stroke(glowColor.opacity(0.85), lineWidth: size * 0.008)
                }
                .offset(x: size * 0.2, y: -size * 0.2)
                .shadow(color: glowColor.opacity(0.4), radius: size * 0.03)

            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(.white.opacity(variant == .light ? 0.24 : 0.1), lineWidth: size * 0.012)
                .padding(size * 0.03)
                .blendMode(.screen)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 24) {
        AppIconView(size: 180, variant: .light)
        AppIconView(size: 180, variant: .dark)
    }
    .padding()
    .background(Color.black.opacity(0.08))
}
