import HealthKit
import SwiftUI
import Combine
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
class HealthKitManager: ObservableObject {
    struct DailySchedule {
        let wake: Date
        let morningPrepEnd: Date
        let focusStart: Date
        let focusEnd: Date
        let caffeineCutoff: Date
        let afternoonStart: Date
        let afternoonEnd: Date
        let sunsetStart: Date
        let sunsetEnd: Date
    }

    private let healthStore = HKHealthStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.florinsima.GoldenHour")
    private let currentPhaseKey = "currentPhase"
    private let currentPhaseEndKey = "currentPhaseEnd"
    private let currentPhaseProgressKey = "currentPhaseProgress"
    private let sunsetTimeKey = "sunsetTime"
    private let wakeUpRefreshKey = "lastWakeUpRefreshTimestamp"
    private let liveActivitiesEnabledKey = "liveActivitiesEnabled"
    private var timer: AnyCancellable?
    private var sunsetObserver: AnyCancellable?
    private var phaseTransitionTask: Task<Void, Never>?
    
    @Published var wakeUpTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
    @Published var currentPhase: DayPhase = .morningPrep
    @Published var phases: [(phase: DayPhase, start: Date, end: Date)] = []
    @Published var isLoading: Bool = true
    
    private(set) var locationManager: LocationManager?
    
    // MARK: - Proprietăți UI
    
    var now: Date { Date() }
    static func makeDailySchedule(wake: Date, sunset: Date) -> DailySchedule {
        let morningPrepEnd = wake.addingTimeInterval(2 * 3600)
        let focusStart = morningPrepEnd
        let focusEnd = focusStart.addingTimeInterval(90 * 60)
        let caffeineCutoff = wake.addingTimeInterval(8 * 3600)
        let afternoonStart = caffeineCutoff
        let sunsetEnd = sunset
        let sunsetStart = max(caffeineCutoff, sunsetEnd.addingTimeInterval(-30 * 60))
        let afternoonEnd = max(afternoonStart, sunsetStart)

        return DailySchedule(
            wake: wake,
            morningPrepEnd: morningPrepEnd,
            focusStart: focusStart,
            focusEnd: focusEnd,
            caffeineCutoff: caffeineCutoff,
            afternoonStart: afternoonStart,
            afternoonEnd: afternoonEnd,
            sunsetStart: sunsetStart,
            sunsetEnd: sunsetEnd
        )
    }

    private var dailySchedule: DailySchedule {
        Self.makeDailySchedule(wake: wakeUpTime, sunset: effectiveSunset)
    }

    var morningPrepEnd: Date { dailySchedule.morningPrepEnd }
    
    var peakFocusStart: Date { dailySchedule.focusStart }
    var peakFocusEnd: Date { dailySchedule.focusEnd }
    
    var peakFocusInterval: String {
        "\(peakFocusStart.formatted(date: .omitted, time: .shortened)) - \(peakFocusEnd.formatted(date: .omitted, time: .shortened))"
    }
    
    var caffeineCutoffDate: Date { dailySchedule.caffeineCutoff }
    var caffeineCutoff: String { caffeineCutoffDate.formatted(date: .omitted, time: .shortened) }
    var afternoonStart: Date { dailySchedule.afternoonStart }
    var afternoonEnd: Date { dailySchedule.afternoonEnd }
    var afternoonInterval: String {
        "\(afternoonStart.formatted(date: .omitted, time: .shortened)) - \(afternoonEnd.formatted(date: .omitted, time: .shortened))"
    }
    
    var effectiveSunset: Date {
        locationManager?.estimatedSunset ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
    }
    
    var sunsetWalkEnd: Date { effectiveSunset }
    
    var currentPhaseEndTime: Date {
        phases.first(where: { $0.phase == currentPhase })?.end ?? now
    }
    
    // MARK: - Refresh Logic
    
    func refresh() {
        updatePhases()

        guard shouldRefreshWakeUpTime() else { return }

        Task(priority: .userInitiated) {
            await fetchWakeUpTime()
        }
    }

    func connectLocationManager(_ locationManager: LocationManager) {
        guard self.locationManager !== locationManager else { return }

        self.locationManager = locationManager
        sunsetObserver = locationManager.$estimatedSunset
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updatePhases()
            }

        updatePhases()
    }
    
    // MARK: - Live Activity Management
    
    func stopAllActivities() {
        #if canImport(ActivityKit)
        Task {
            for activity in Activity<GoldenHourAttributes>.activities {
                let content = ActivityContent(state: activity.content.state, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
    
    func updateLiveActivity() {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let defaults = UserDefaults.standard
        let isEnabled = defaults.object(forKey: liveActivitiesEnabledKey) as? Bool ?? true
        guard isEnabled else { 
            stopAllActivities()
            return 
        }

        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
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
        case .afternoon:
            start = afternoonStart
            translationKey = "afternoon_reset"
        case .sunset: 
            start = phases.first(where: { $0.phase == .sunset })?.start ?? effectiveSunset
            translationKey = "sunset_walk"
        case .idle: 
            start = Date()
            translationKey = "idle_phase"
        }
        
        let total = max(1, endTime.timeIntervalSince(start))
        let progress = max(0, min(1.0, Date().timeIntervalSince(start) / total))
        
        let state = GoldenHourAttributes.ContentState(
            phaseName: AppTranslation.get(translationKey, lang: lang),
            phaseKey: phase.rawValue,
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
                self.sharedDefaults?.set(Date().timeIntervalSince1970, forKey: self.wakeUpRefreshKey)
                self.updatePhases()
                self.isLoading = false
            }
        }
        healthStore.execute(query)
    }

    private func shouldRefreshWakeUpTime(now: Date = Date()) -> Bool {
        guard let lastRefreshTimestamp = sharedDefaults?.object(forKey: wakeUpRefreshKey) as? Double else {
            return true
        }

        let lastRefreshDate = Date(timeIntervalSince1970: lastRefreshTimestamp)
        return wakeRefreshAnchor(for: lastRefreshDate) != wakeRefreshAnchor(for: now)
    }

    private func wakeRefreshAnchor(for date: Date) -> Date {
        let calendar = Calendar.current

        if let fourAMToday = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: date) {
            if date >= fourAMToday {
                return fourAMToday
            }

            return calendar.date(byAdding: .day, value: -1, to: fourAMToday) ?? fourAMToday
        }

        return calendar.startOfDay(for: date)
    }
    
    func updatePhases() {
        let schedule = dailySchedule
        
        self.phases = [
            (.morningPrep, schedule.wake, schedule.morningPrepEnd),
            (.focus, schedule.focusStart, schedule.focusEnd),
            (.caffeine, schedule.focusEnd, schedule.caffeineCutoff),
            (.afternoon, schedule.afternoonStart, schedule.afternoonEnd),
            (.sunset, schedule.sunsetStart, schedule.sunsetEnd),
            (.idle, schedule.sunsetEnd, schedule.wake.addingTimeInterval(24 * 3600))
        ]
        
        let now = Date()
        let newPhase = phases.first(where: { now >= $0.start && now < $0.end })?.phase ?? .idle
        
        if self.currentPhase != newPhase {
            self.currentPhase = newPhase
        }

        persistWidgetState(schedule: schedule)
        schedulePhaseTransition()
        updateLiveActivity()
    }

    private func persistWidgetState(schedule: DailySchedule) {
        sharedDefaults?.set(wakeUpTime.timeIntervalSince1970, forKey: "wakeUpTime")
        sharedDefaults?.set(schedule.sunsetEnd.timeIntervalSince1970, forKey: sunsetTimeKey)
        sharedDefaults?.set(currentPhase.rawValue, forKey: currentPhaseKey)
        sharedDefaults?.set(currentPhaseEndTime.timeIntervalSince1970, forKey: currentPhaseEndKey)

        if let current = phases.first(where: { $0.phase == currentPhase }) {
            let total = max(1, current.end.timeIntervalSince(current.start))
            let progress = max(0, min(1.0, Date().timeIntervalSince(current.start) / total))
            sharedDefaults?.set(progress, forKey: currentPhaseProgressKey)
        } else {
            sharedDefaults?.set(0.0, forKey: currentPhaseProgressKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func schedulePhaseTransition() {
        phaseTransitionTask?.cancel()

        let now = Date()
        guard let nextTransition = phases.first(where: { $0.end > now })?.end else { return }

        let delay = max(0, nextTransition.timeIntervalSince(now) + 0.1)
        phaseTransitionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.updatePhases()
        }
    }
}
