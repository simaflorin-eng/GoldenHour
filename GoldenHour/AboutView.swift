import SwiftUI

struct AboutView: View {
    @ObservedObject var healthManager: HealthKitManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var showingHubermanDetails = false

    private var phase: DayPhase { healthManager.currentPhase }

    var body: some View {
        ZStack {
            aboutBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    phaseSection

                    scienceSection

                    philosophySection

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 44)
            }
        }
        .navigationTitle(AppTranslation.get("about_title", lang: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(colorScheme, for: .navigationBar)
        .sheet(isPresented: $showingHubermanDetails) {
            hubermanDetailsView
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.orbGlow(phase))

                Text(AppTranslation.get("about_title", lang: appLanguage).uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.8)
                    .foregroundColor(Color.orbGlow(phase))
            }

            Text(AppTranslation.get("about_q", lang: appLanguage))
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundColor(Color.pulsePrimaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Text(AppTranslation.get("about_intro", lang: appLanguage))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineSpacing(4)
                .foregroundColor(Color.pulseSecondaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 24))
        .padding(.top, 6)
    }

    private var phaseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(AppTranslation.get("stages_header", lang: appLanguage))

            VStack(spacing: 0) {
                aboutPhaseRow(title: "morning_prep_t", info: "morning_prep_d", icon: "sunrise.fill", phaseColor: Color.orbGlow(.morningPrep))
                divider
                aboutPhaseRow(title: "peak_focus_t", info: "peak_focus_d", icon: "brain.head.profile", phaseColor: Color.orbGlow(.focus))
                divider
                aboutPhaseRow(title: "caffeine_cutoff_t", info: "caffeine_cutoff_d", icon: "cup.and.saucer.fill", phaseColor: Color.orbGlow(.caffeine))
                divider
                aboutPhaseRow(title: "afternoon_reset_t", info: "afternoon_reset_d", icon: "sun.max.trianglebadge.exclamationmark", phaseColor: Color.orbGlow(.afternoon))
                divider
                aboutPhaseRow(title: "sunset_walk_t", info: "sunset_walk_d", icon: "sunset.fill", phaseColor: Color.orbGlow(.sunset))
            }
            .background(cardBackground(cornerRadius: 20))
        }
    }

    private var scienceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(AppTranslation.get("science_header", lang: appLanguage))

            Button {
                showingHubermanDetails = true
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    iconTile("checkmark.seal.fill", color: Color.orbGlow(phase))

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(AppTranslation.get("science_header", lang: appLanguage))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(Color.pulsePrimaryText(colorScheme))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.pulseSecondaryText(colorScheme))
                        }

                        Text(AppTranslation.get("science_content", lang: appLanguage))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .lineSpacing(4)
                            .foregroundColor(Color.pulseSecondaryText(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
    }

    private var philosophySection: some View {
        HStack(alignment: .top, spacing: 14) {
            iconTile("bolt.shield.fill", color: Color.pulseAmber)

            VStack(alignment: .leading, spacing: 7) {
                Text(AppTranslation.get("philosophy_title", lang: appLanguage))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color.pulsePrimaryText(colorScheme))

                Text(AppTranslation.get("science_disclaimer", lang: appLanguage))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .lineSpacing(3)
                    .foregroundColor(Color.pulseSecondaryText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 20))
    }

    private var hubermanDetailsView: some View {
        NavigationStack {
            ZStack {
                aboutBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 14) {
                            iconTile("checkmark.seal.fill", color: Color.orbGlow(phase))

                            Text(AppTranslation.get("science_content", lang: appLanguage))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .lineSpacing(4)
                                .foregroundColor(Color.pulseSecondaryText(colorScheme))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(cardBackground(cornerRadius: 20))

                        Text(AppTranslation.get("science_disclaimer", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .lineSpacing(3)
                            .foregroundColor(Color.pulseSecondaryText(colorScheme))
                            .padding(14)
                            .background(cardBackground(cornerRadius: 16))

                        VStack(spacing: 0) {
                            hubermanPoint(title: "huberman_morning_light_t", description: "huberman_morning_light_d", icon: "sun.max.fill", color: .yellow)
                            divider
                            hubermanPoint(title: "huberman_delay_caffeine_t", description: "huberman_delay_caffeine_d", icon: "timer", color: .orange)
                            divider
                            hubermanPoint(title: "huberman_focus_window_t", description: "huberman_focus_window_d", icon: "brain.head.profile", color: .blue)
                            divider
                            hubermanPoint(title: "huberman_sunset_view_t", description: "huberman_sunset_view_d", icon: "sunset.fill", color: .indigo)
                            divider
                            hubermanPoint(title: "huberman_caffeine_cutoff_t", description: "huberman_caffeine_cutoff_d", icon: "cup.and.saucer.fill", color: .brown)
                        }
                        .background(cardBackground(cornerRadius: 20))
                    }
                    .padding(24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(AppTranslation.get("science_header", lang: appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTranslation.get("close", lang: appLanguage)) {
                        showingHubermanDetails = false
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color.pulseAmber)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.pulseBackground(colorScheme))
    }

    private func aboutPhaseRow(title: String, info: String, icon: String, phaseColor: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            iconTile(icon, color: phaseColor)

            VStack(alignment: .leading, spacing: 6) {
                Text(AppTranslation.get(title, lang: appLanguage))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.pulsePrimaryText(colorScheme))

                Text(AppTranslation.get(info, lang: appLanguage))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineSpacing(3)
                    .foregroundColor(Color.pulseSecondaryText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }

    private func hubermanPoint(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            iconTile(icon, color: color)

            VStack(alignment: .leading, spacing: 6) {
                Text(AppTranslation.get(title, lang: appLanguage))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.pulsePrimaryText(colorScheme))

                Text(AppTranslation.get(description, lang: appLanguage))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineSpacing(3)
                    .foregroundColor(Color.pulseSecondaryText(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .tracking(2)
            .foregroundColor(Color.pulseSecondaryText(colorScheme))
    }

    private func iconTile(_ icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.18))
                .frame(width: 38, height: 38)

            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.pulseChipFill(colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.pulseChipStroke(colorScheme), lineWidth: 0.65)
            )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.pulseChipStroke(colorScheme))
            .frame(height: 0.65)
            .padding(.leading, 68)
    }

    private var aboutBackground: some View {
        ZStack {
            Color.pulseBackground(colorScheme)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.bgGlow(phase).opacity(colorScheme == .dark ? 0.32 : 0.14),
                    Color.bgGlow(phase).opacity(colorScheme == .dark ? 0.08 : 0.05),
                    .clear
                ],
                center: .init(x: 0.5, y: -0.08),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }
}
