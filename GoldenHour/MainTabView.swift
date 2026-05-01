import SwiftUI
import StoreKit
import UIKit

struct MainTabView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.requestReview) private var requestReview
    @State private var didConfigureManagers = false
    @State private var showReviewPrompt = false
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("reviewPromptLaunchCount") private var reviewPromptLaunchCount = 0
    @AppStorage("reviewPromptLastShownAt") private var reviewPromptLastShownAt = 0.0
    @AppStorage("reviewPromptCompleted") private var reviewPromptCompleted = false

    private let reviewPromptStartCount = 8
    private let reviewPromptRepeatInterval = 12
    private let reviewPromptCooldown: TimeInterval = 60 * 60 * 24 * 45
    private let appStoreReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id6762508692?action=write-review")
    
    var body: some View {
        TabView {
            ContentView(healthManager: healthManager, locationManager: locationManager)
                .tabItem {
                    Label(AppTranslation.get("dashboard", lang: appLanguage), systemImage: "clock.fill")
                }
            
            SettingsView(healthManager: healthManager)
                .tabItem {
                    Label(AppTranslation.get("settings", lang: appLanguage), systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            guard !didConfigureManagers else { return }
            didConfigureManagers = true

            healthManager.connectLocationManager(locationManager)
            registerLaunchAndScheduleReviewPrompt()
        }
        .alert(
            AppTranslation.get("review_prompt_title", lang: appLanguage),
            isPresented: $showReviewPrompt
        ) {
            Button(AppTranslation.get("review_prompt_cta", lang: appLanguage)) {
                reviewPromptCompleted = true
                openReviewPage()
            }

            Button(AppTranslation.get("review_prompt_later", lang: appLanguage), role: .cancel) {}
        } message: {
            Text(AppTranslation.get("review_prompt_message", lang: appLanguage))
        }
    }

    private func registerLaunchAndScheduleReviewPrompt() {
        guard !reviewPromptCompleted else { return }

        reviewPromptLaunchCount += 1

        guard shouldPresentReviewPrompt(now: Date()) else { return }

        reviewPromptLastShownAt = Date().timeIntervalSince1970
        showReviewPrompt = true
    }

    private func shouldPresentReviewPrompt(now: Date) -> Bool {
        guard reviewPromptLaunchCount >= reviewPromptStartCount else { return false }

        let launchesSinceStart = reviewPromptLaunchCount - reviewPromptStartCount
        let isPromptLaunch = launchesSinceStart % reviewPromptRepeatInterval == 0
        guard isPromptLaunch else { return false }

        guard reviewPromptLastShownAt > 0 else { return true }

        let elapsed = now.timeIntervalSince1970 - reviewPromptLastShownAt
        return elapsed >= reviewPromptCooldown
    }

    private func openReviewPage() {
        guard let appStoreReviewURL, UIApplication.shared.canOpenURL(appStoreReviewURL) else {
            requestReview()
            return
        }

        UIApplication.shared.open(appStoreReviewURL)
    }
}
