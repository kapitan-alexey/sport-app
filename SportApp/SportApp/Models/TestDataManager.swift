import Foundation

/*
 ВНИМАНИЕ: Этот файл больше не используется!
 
 Приложение теперь получает данные из API по адресу:
 http://localhost:8000/events/
 
 Данные больше не создаются локально и не сохраняются в Core Data.
 Все события теперь приходят из внешнего сервиса в формате JSON.
 
 Если нужно вернуться к локальным тестовым данным,
 используйте предыдущую версию этого файла с Core Data.
 
 Текущая архитектура:
 - ApiService.swift - для работы с API
 - SportModels.swift - модели данных для JSON
 - EventsDataManager - менеджер состояния событий
 */

// MARK: - TestDataManager (УСТАРЕЛ)
class TestDataManager {
    
    static func createMockEvents() -> [SportEvent] {
        // Можно использовать для отладки без сервера
        return []
    }
    
    // Все остальные методы удалены, так как Core Data больше не используется
}
