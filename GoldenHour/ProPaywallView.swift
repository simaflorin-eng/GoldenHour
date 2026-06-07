import SwiftUI

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var proStore: ProStore
    @AppStorage("appLanguage") private var appLanguage = "en"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(secondaryText)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(chromeFill))
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 12) {
                    Text(t("pro_title"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(primaryText)
                        .multilineTextAlignment(.center)

                    Text(t("pro_subtitle"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    benefit(icon: "rectangle.on.rectangle.angled", title: t("pro_benefit_widgets_title"), detail: t("pro_benefit_widgets_detail"))
                    benefit(icon: "timer", title: t("pro_benefit_live_title"), detail: t("pro_benefit_live_detail"))
                    benefit(icon: "sparkles", title: t("pro_benefit_complete_title"), detail: t("pro_benefit_complete_detail"))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(chromeFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(chromeStroke, lineWidth: 0.75)
                        )
                )

                VStack(spacing: 10) {
                    Button {
                        Task {
                            await proStore.purchasePro()
                            if proStore.isProUnlocked {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if proStore.isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(t("pro_purchase_button") + " - " + proStore.displayPrice)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Color(red: 0.06, green: 0.04, blue: 0.02))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(Color.pulseAmber))
                    }
                    .buttonStyle(.plain)
                    .disabled(proStore.isLoading)

                    Button {
                        Task {
                            await proStore.restorePurchases()
                            if proStore.isProUnlocked {
                                dismiss()
                            }
                        }
                    } label: {
                        Text(t("pro_restore_button"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(secondaryText)
                    }
                    .buttonStyle(.plain)
                    .disabled(proStore.isLoading)
                }

                if let errorMessage = proStore.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Text(t("pro_payment_note"))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(secondaryText.opacity(0.82))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
        }
    }

    private func t(_ key: String) -> String {
        AppTranslation.get(key, lang: appLanguage)
    }

    private func benefit(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.pulseAmber)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.pulseAmber.opacity(colorScheme == .dark ? 0.12 : 0.18)))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(primaryText)
                Text(detail)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var backgroundColors: [Color] {
        colorScheme == .dark
            ? [Color.pulseDeepBg, Color(red: 0.08, green: 0.055, blue: 0.03)]
            : [Color(red: 0.99, green: 0.965, blue: 0.91), Color(red: 0.96, green: 0.91, blue: 0.80)]
    }

    private var primaryText: Color {
        Color.pulsePrimaryText(colorScheme)
    }

    private var secondaryText: Color {
        Color.pulseSecondaryText(colorScheme)
    }

    private var chromeFill: Color {
        Color.pulseChipFill(colorScheme)
    }

    private var chromeStroke: Color {
        Color.pulseChipStroke(colorScheme)
    }
}
