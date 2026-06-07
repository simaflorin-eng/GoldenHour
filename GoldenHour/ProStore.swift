import Foundation
import Combine
import StoreKit
import WidgetKit

@MainActor
final class ProStore: ObservableObject {
    static let productID = "com.florinsima.GoldenHour.pro"
    private let sharedDefaults = UserDefaults(suiteName: "group.com.florinsima.GoldenHour")
    private let proUnlockedKey = "proUnlocked"

    @Published private(set) var isProUnlocked: Bool
    @Published private(set) var product: Product?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init() {
        let savedValue = UserDefaults.standard.bool(forKey: proUnlockedKey)
            || (sharedDefaults?.bool(forKey: proUnlockedKey) ?? false)
        self.isProUnlocked = savedValue

        Task {
            await refresh()
            await observeTransactions()
        }
    }

    var displayPrice: String {
        product?.displayPrice ?? "$3.99"
    }

    private var appLanguage: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }

    func refresh() async {
        await loadProduct()
        await refreshEntitlements()
    }

    func purchasePro() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let product = try await loadProductIfNeeded()
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = AppTranslation.get("pro_error_unverified", lang: appLanguage)
                    return
                }

                unlockPro()
                await transaction.finish()
            case .userCancelled, .pending:
                return
            @unknown default:
                return
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProductIfNeeded() async throws -> Product {
        if let product {
            return product
        }

        let products = try await Product.products(for: [Self.productID])
        guard let product = products.first else {
            throw ProStoreError.productUnavailable
        }

        self.product = product
        return product
    }

    private func refreshEntitlements() async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == Self.productID else { continue }
            guard transaction.revocationDate == nil else { continue }
            hasPro = true
            break
        }

        if hasPro {
            unlockPro()
        } else if !UserDefaults.standard.bool(forKey: proUnlockedKey) {
            setProUnlocked(false)
        }
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.productID, transaction.revocationDate == nil {
                unlockPro()
            }
            await transaction.finish()
        }
    }

    private func unlockPro() {
        setProUnlocked(true)
    }

    private func setProUnlocked(_ value: Bool) {
        isProUnlocked = value
        UserDefaults.standard.set(value, forKey: proUnlockedKey)
        sharedDefaults?.set(value, forKey: proUnlockedKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum ProStoreError: LocalizedError {
    case productUnavailable

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
            return AppTranslation.get("pro_error_unavailable", lang: language)
        }
    }
}
