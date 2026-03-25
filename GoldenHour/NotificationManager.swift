import UserNotifications

class NotificationManager {
    static let instance = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("DEBUG: Permisiune notificări: \(granted)")
        }
    }
    
    func scheduleNotification(id: String, title: String, body: String, at date: Date) {
        // Ștergem notificările vechi cu același ID pentru a nu avea duplicate
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        
        // Nu programăm dacă data este deja în trecut
        guard date > Date.now else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        print("DEBUG: Notificare programată pentru \(id) la ora \(date.formatted())")
    }
}
