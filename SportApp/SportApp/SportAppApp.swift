import SwiftUI
import FirebaseCore
import FirebaseAnalytics

@main
struct SportsEventsApp: App {
    
    init() {
        FirebaseApp.configure()
        
        // Настройки для тестирования Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        #if DEBUG
        // В новых версиях Firebase Analytics автоматически управляет сессиями
        // Включаем подробные логи для отладки
        print("🔥 Firebase Analytics настроен для DEBUG режима")
        print("📊 Analytics будет отправлять данные автоматически")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
