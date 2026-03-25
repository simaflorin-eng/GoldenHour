import HealthKit
import SwiftUI
import Combine
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.florinsima.GoldenHour")
    private var timer: AnyCancellable?
    
    @Published var wakeUpTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
    @Published var currentPhase: DayPhase = .morningPrep
    @Published var phases: [(phase: DayPhase, start: Date, end: Date)] = []
    @Published var isLoading: Bool = true
    
    var locationManager: LocationManager?
    
    // MARK: - Proprietăți UI
    
    var now: Date { Date() }
    
    var peakFocusStart: Date { phases.first(where: { $0.phase == .focus })?.start ?? now }
    var peakFocusEnd: Date { phases.first(where: { $0.phase == .focus })?.end ?? now }
    
    var peakFocusInterval: String {
        "\(peakFocusStart.formatted(date: .omitted, time: .shortened)) - \(peakFocusEnd.formatted(date: .omitted, time: .shortened))"
    }
    
    var caffeineCutoffDate: Date { phases.first(where: { $0.phase == .caffeine })?.end ?? now }
    var caffeineCutoff: String { caffeineCutoffDate.formatted(date: .omitted, time: .shortened) }
    
    var effectiveSunset: Date {
        locationManager?.estimatedSunset ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
    }
    
    var sunsetWalkEnd: Date { phases.first(where: { $0.phase == .sunset })?.end ?? effectiveSunset }
    
    var currentPhaseEndTime: Date {
        phases.first(where: { $0.phase == currentPhase })?.end ?? now
    }
    
    // MARK: - Refresh Logic
    
    func refresh() {
        Task {
            await fetchWakeUpTime()
        }
    }
    
    // MARK: - Live Activity Management
    
    func stopAllActivities() {
        #if canImport(ActivityKit)
        Task {
            for activity in Activity<GoldenHourAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        #endif
    }
    
    func updateLiveActivity() {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let isEnabled = UserDefaults.standard.bool(forKey: "liveActivitiesEnabled")
        guard isEnabled else { 
            stopAllActivities()
            return 
        }

        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "ro"
        let phase = currentPhase
        
        if phase == .idle {
            stopAllActivities()
            return
        }

        let endTime = currentPhaseEndTime
        let start: Date
        let translationKey: String
        
        switch phase {
        case .morningPrep: 
            start = wakeUpTime
            translationKey = "morning_prep"
        case .focus: 
            start = peakFocusStart
            translationKey = "peak_focus"
        case .caffeine: 
            start = peakFocusEnd
            translationKey = "caffeine_cutoff"
        case .sunset: 
            start = caffeineCutoffDate
            translationKey = "sunset_walk"
        case .idle: 
            start = Date()
            translationKey = "idle_phase"
        }
        
        let total = max(1, endTime.timeIntervalSince(start))
        let progress = max(0, min(1.0, Date().timeIntervalSince(start) / total))
        
        let state = GoldenHourAttributes.ContentState(
            phaseName: AppTranslation.get(translationKey, lang: lang),
            phaseIcon: phase.icon,
            phaseColor: phase.hexColor,
            endTime: endTime,
            progress: progress
        )
        
        Task {
            if let existingActivity = Activity<GoldenHourAttributes>.activities.first {
                let content = ActivityContent(state: state, staleDate: nil)
                await existingActivity.update(content)
            } else {
                do {
                    let attributes = GoldenHourAttributes()
                    let content = ActivityContent(state: state, staleDate: nil)
                    _ = try Activity.request(attributes: attributes, content: content)
                } catch {
                    print("DEBUG: Eroare Live Activity: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }
    
    // MARK: - Logica Principală
    
    init() {
        if let savedWake = sharedDefaults?.double(forKey: "wakeUpTime"), savedWake > 0 {
            self.wakeUpTime = Date(timeIntervalSince1970: savedWake)
            self.updatePhases()
        }
        
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePhases()
            }
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        try? await healthStore.requestAuthorization(toShare: [], read: [sleepType])
        await fetchWakeUpTime()
    }
    
    func fetchWakeUpTime() async {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        
        // Căutăm date de la ora 4:00 AM a zilei curente (sau ieri dacă e foarte devreme)
        let now = Date()
        let lookbackDate = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: now) ?? 
                           calendar.date(byAdding: .hour, value: -12, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: lookbackDate, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 30, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let self = self else { return }
            
            // LOGICĂ NOUĂ: Găsim ultima perioadă de somn real (nu doar "în pat")
            // Ignorăm momentele de tip "awake" sau "inBed" pentru a găsi ora reală de trezire
            let sleepSamples = (samples as? [HKCategorySample]) ?? []
            let actualSleep = sleepSamples.first { sample in
                sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue &&
                sample.value != HKCategoryValueSleepAnalysis.awake.rawValue
            }
            
            // Ora de trezire este momentul în care s-a terminat ultimul eșantion de somn
            let wakeDate = actualSleep?.endDate ?? 
                           calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
            
            Task { @MainActor in
                self.wakeUpTime = wakeDate
                self.sharedDefaults?.set(wakeDate.timeIntervalSince1970, forKey: "wakeUpTime")
                self.updatePhases()
                self.isLoading = false
            }
        }
        healthStore.execute(query)
    }
    
    func updatePhases() {
        let wake = wakeUpTime
        let sunset = effectiveSunset
        
        let p1End = wake.addingTimeInterval(2 * 3600)
        let p2End = wake.addingTimeInterval(6 * 3600)
        let p3End = wake.addingTimeInterval(8.5 * 3600) 
        
        // Faza de Apus se termină la apusul efectiv (cu minim 30 minute alocate după limita de cafeină)
        let p4End = max(sunset, p3End.addingTimeInterval(1800))
        
        self.phases = [
            (.morningPrep, wake, p1End),
            (.focus, p1End, p2End),
            (.caffeine, p2End, p3End),
            (.sunset, p3End, p4End),
            (.idle, p4End, wake.addingTimeInterval(24 * 3600))
        ]
        
        let now = Date()
        let newPhase = phases.first(where: { now >= $0.start && now < $0.end })?.phase ?? .idle
        
        if self.currentPhase != newPhase {
            self.currentPhase = newPhase
        }
        
        updateLiveActivity()
    }
}
