import CoreLocation
import Combine
import Foundation

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var estimatedSunset: Date?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }

        manager.startUpdatingLocation()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = locations.first?.coordinate {
            Task { @MainActor in
                self.location = coord
                self.estimatedSunset = self.calculateSunset(lat: coord.latitude, lon: coord.longitude, date: Date())
            }
        }
        manager.stopUpdatingLocation()
    }

    func calculateSunset(lat: Double, lon: Double, date: Date) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 0)
        let lngHour = lon / 15.0
        let t = dayOfYear + ((18.0 - lngHour) / 24.0)
        let M = (0.9856 * t) - 3.2891
        var L = M + (1.916 * sin(M.toRadians())) + (0.020 * sin(2 * M.toRadians())) + 282.634
        L = L.normalizingTo360()
        var RA = atan(0.91764 * tan(L.toRadians())).toDegrees()
        RA = RA.normalizingTo360()
        let lQuadrant = floor(L / 90.0) * 90.0
        let raQuadrant = floor(RA / 90.0) * 90.0
        RA = RA + (lQuadrant - raQuadrant)
        RA = RA / 15.0
        let sinDec = 0.39782 * sin(L.toRadians())
        let cosDec = cos(asin(sinDec))
        let zenith = 90.833
        let cosH = (cos(zenith.toRadians()) - (sinDec * sin(lat.toRadians()))) / (cosDec * cos(lat.toRadians()))
        guard cosH >= -1 && cosH <= 1 else { return nil }
        let H = acos(cosH).toDegrees() / 15.0
        let T = H + RA - (0.06571 * t) - 6.622
        var ut = T - lngHour
        ut = ut.normalizingTo24()
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let baseDate = calendar.date(from: components) else { return nil }
        return baseDate.addingTimeInterval(ut * 3600)
    }
}

private extension Double {
    func toRadians() -> Double { self * .pi / 180.0 }
    func toDegrees() -> Double { self * 180.0 / .pi }
    func normalizingTo360() -> Double {
        var value = self
        while value < 0 { value += 360 }
        while value >= 360 { value -= 360 }
        return value
    }
    func normalizingTo24() -> Double {
        var value = self
        while value < 0 { value += 24 }
        while value >= 24 { value -= 24 }
        return value
    }
}
