import HealthKit
import SwiftUI
import Combine
import WidgetKit

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.florinsima.GoldenHour")
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        healthStore.requestAuthorization(toShare: nil, read: [sleepType]) { [weak self] success, _ in
            if success {
                self?.fetchWakeUpTime()
            }
        }
    }
    
    func fetchWakeUpTime() {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            // Căutăm ultima perioadă de trezire de după somn
            if let lastWakeUp = samples.first(where: { $0.value == HKCategoryValueSleepAnalysis.awake.rawValue }) {
                DispatchQueue.main.async {
                    self?.sharedDefaults?.set(lastWakeUp.endDate.timeIntervalSince1970, forKey: "wakeUpTime")
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
        healthStore.execute(query)
    }
}
