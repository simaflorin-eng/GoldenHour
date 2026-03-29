import SwiftUI
import Charts
import HealthKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
struct ContentView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    
    private let meshPoints: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(1.0, 1.0)
    ]

    private var meshColors: [Color] {
        let intensity = colorScheme == .dark ? 0.9 : 0.6
        let phase = healthManager.currentPhase
        let base: Color
        switch phase {
        case .morningPrep: base = .cyan
        case .focus: base = .orange
        case .caffeine: base = Color(hexRGB: phase.hexColor, fallback: .brown)
        case .afternoon: base = Color(hexRGB: phase.hexColor, fallback: .green)
        case .sunset: base = .indigo
        case .idle: base = .purple
        }
        return [base.opacity(intensity), base.opacity(intensity * 0.5), base.opacity(0.3), .black]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradient(width: 2, height: 2, points: meshPoints, colors: meshColors)
                    .ignoresSafeArea()
                    .blur(radius: 50)
                    .animation(.spring(response: 1.5, dampingFraction: 0.9), value: healthManager.currentPhase)
                
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                    .opacity(colorScheme == .dark ? 0.35 : 0.15)

                dashboardView
            }
        }
    }

    private var dashboardView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerView
                
                VStack(spacing: 15) {
                    NeonProgressView(healthManager: healthManager, locationManager: locationManager)
                }
                .padding(.vertical, 25)
                .background(.ultraThinMaterial.opacity(0.5))
                .cornerRadius(40)
                .padding(.horizontal)

                VStack(spacing: 0) {
                    TimelineRow(
                        title: AppTranslation.get("morning_prep", lang: appLanguage),
                        subtitle: "\(healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened)) - \(healthManager.peakFocusStart.formatted(date: .omitted, time: .shortened))",
                        icon: DayPhase.morningPrep.icon,
                        color: .cyan,
                        isNow: healthManager.currentPhase == .morningPrep,
                        infoKey: "about_morning_prep_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("peak_focus", lang: appLanguage),
                        subtitle: healthManager.peakFocusInterval,
                        icon: DayPhase.focus.icon,
                        color: .orange,
                        isNow: healthManager.currentPhase == .focus,
                        infoKey: "about_focus_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("caffeine_cutoff", lang: appLanguage),
                        subtitle: healthManager.caffeineCutoff,
                        icon: DayPhase.caffeine.icon,
                        color: Color(hexRGB: DayPhase.caffeine.hexColor, fallback: .brown),
                        isNow: healthManager.currentPhase == .caffeine,
                        infoKey: "about_caffeine_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("afternoon_reset", lang: appLanguage),
                        subtitle: healthManager.afternoonInterval,
                        icon: DayPhase.afternoon.icon,
                        color: Color(hexRGB: DayPhase.afternoon.hexColor, fallback: .green),
                        isNow: healthManager.currentPhase == .afternoon,
                        infoKey: "about_afternoon_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("sunset_walk", lang: appLanguage),
                        subtitle: healthManager.sunsetWalkEnd.formatted(date: .omitted, time: .shortened),
                        icon: DayPhase.sunset.icon,
                        color: .indigo,
                        isNow: healthManager.currentPhase == .sunset,
                        infoKey: "about_sunset_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("idle_phase", lang: appLanguage),
                        subtitle: AppTranslation.get("legend_idle", lang: appLanguage),
                        icon: DayPhase.idle.icon,
                        color: .purple,
                        isNow: healthManager.currentPhase == .idle,
                        infoKey: "about_idle_info"
                    )
                }
                .background(.ultraThinMaterial)
                .cornerRadius(40)
                .padding(.horizontal)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(AppTranslation.get("legend_\(healthManager.currentPhase.rawValue)", lang: appLanguage).uppercased())
                .font(.system(size: 9, weight: .black))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.primary.opacity(0.08))
                .clipShape(Capsule())
            Text(healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 80, weight: .ultraLight, design: .rounded))
            Text(AppTranslation.get("wake_up_label", lang: appLanguage).uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.primary.opacity(0.4))
        }
        .padding(.top, 20)
    }
}

struct NeonProgressView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 12) { 
            GeometryReader { geo in
                let spacing: CGFloat = 6
                let horizontalPadding: CGFloat = 40 
                let usableWidth = geo.size.width - horizontalPadding - (4 * spacing)
                let thresholds = calculateThresholds()
                
                HStack(spacing: spacing) {
                    NeonSegment(phase: .morningPrep, color: .cyan, width: usableWidth * thresholds.pFocusStart, isActive: healthManager.currentPhase == .morningPrep, progress: calculateInternalProgress(for: .morningPrep))
                    NeonSegment(phase: .focus, color: .orange, width: usableWidth * (thresholds.pFocusEnd - thresholds.pFocusStart), isActive: healthManager.currentPhase == .focus, progress: calculateInternalProgress(for: .focus))
                    NeonSegment(phase: .caffeine, color: Color(hexRGB: DayPhase.caffeine.hexColor, fallback: .brown), width: usableWidth * (thresholds.pCaffeineEnd - thresholds.pFocusEnd), isActive: healthManager.currentPhase == .caffeine, progress: calculateInternalProgress(for: .caffeine))
                    NeonSegment(phase: .afternoon, color: Color(hexRGB: DayPhase.afternoon.hexColor, fallback: .green), width: usableWidth * (thresholds.pSunsetStart - thresholds.pCaffeineEnd), isActive: healthManager.currentPhase == .afternoon, progress: calculateInternalProgress(for: .afternoon))
                    NeonSegment(phase: .sunset, color: .indigo, width: usableWidth * max(0, (1.0 - thresholds.pSunsetStart)), isActive: healthManager.currentPhase == .sunset, progress: calculateInternalProgress(for: .sunset))
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 24)
            
            if healthManager.currentPhase != .idle {
                HStack(spacing: 4) {
                    Image(systemName: "timer").font(.system(size: 10, weight: .bold))
                    Text(healthManager.currentPhaseEndTime, style: .timer).font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.primary.opacity(0.6))
                .padding(.top, 5)
            }
        }
    }

    private func calculateInternalProgress(for phase: DayPhase) -> Double {
        let now = healthManager.now
        if phase == .idle { return 0 }
        
        guard let phaseData = healthManager.phases.first(where: { $0.phase == phase }) else { return 0 }
        let start = phaseData.start
        let end = phaseData.end
        let total = end.timeIntervalSince(start)
        
        return total > 0 ? max(0, min(1.0, now.timeIntervalSince(start) / total)) : 1.0
    }

    private func calculateThresholds() -> BioThresholds {
        // Obținem segmentele direct din array-ul calculat
        guard let p1 = healthManager.phases.first(where: { $0.phase == .morningPrep }),
              let p2 = healthManager.phases.first(where: { $0.phase == .focus }),
              let p3 = healthManager.phases.first(where: { $0.phase == .caffeine }),
              let p4 = healthManager.phases.first(where: { $0.phase == .afternoon }),
              let p5 = healthManager.phases.first(where: { $0.phase == .sunset }) else {
            return BioThresholds(pFocusStart: 0, pFocusEnd: 0, pCaffeineEnd: 0, pSunsetStart: 0)
        }
        
        let start = p1.start
        let end = p5.end
        let total = max(1, end.timeIntervalSince(start))
        
        return BioThresholds(
            pFocusStart: max(0, min(1.0, p2.start.timeIntervalSince(start) / total)),
            pFocusEnd: max(0, min(1.0, p3.start.timeIntervalSince(start) / total)),
            pCaffeineEnd: max(0, min(1.0, p4.start.timeIntervalSince(start) / total)),
            pSunsetStart: max(0, min(1.0, p5.start.timeIntervalSince(start) / total))
        )
    }

    struct BioThresholds {
        let pFocusStart: Double
        let pFocusEnd: Double
        let pCaffeineEnd: Double
        let pSunsetStart: Double
    }
}

struct NeonSegment: View {
    let phase: DayPhase
    let color: Color
    let width: CGFloat
    let isActive: Bool
    let progress: Double
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.12)).frame(width: max(2, width), height: 14)
            RoundedRectangle(cornerRadius: 7).fill(color.opacity(isActive ? 1.0 : 0.4)).frame(width: max(0, width * progress), height: 14)
            if isActive {
                RoundedRectangle(cornerRadius: 7).fill(color).frame(width: max(0, width * progress), height: 14).shadow(color: color.opacity(0.8), radius: 5).blur(radius: 1)
            }
        }
        .frame(height: 18)
    }
}

struct TimelineRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isNow: Bool
    let infoKey: String
    @State private var showInfo = false
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    var body: some View {
        HStack(spacing: 16) {
            ZStack { 
                Circle().fill(color.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(color) 
            }
            
            VStack(alignment: .leading, spacing: 2) { 
                HStack(spacing: 8) {
                    Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    if isNow {
                        Text(AppTranslation.get("now_label", lang: appLanguage).uppercased())
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(color.opacity(0.15))
                            .foregroundColor(color)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: color.opacity(0.5), radius: 4)
                    }
                }
                Text(subtitle).font(.system(size: 13, design: .rounded)).foregroundColor(.secondary) 
            }
            Spacer()
            
            Button { showInfo.toggle() } label: { Image(systemName: "info.circle").foregroundColor(.primary.opacity(0.2)) }
            .popover(isPresented: $showInfo) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.primary)
                    Text(AppTranslation.get(infoKey, lang: appLanguage)).font(.system(size: 14)).lineSpacing(3).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                .padding(20).frame(width: 280).presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 14).padding(.horizontal, 20)
    }
}
