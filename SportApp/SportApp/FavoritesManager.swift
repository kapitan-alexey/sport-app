import Foundation
import FirebaseAnalytics

// MARK: - Favorites Manager
/// Менеджер для управления избранными спортивными событиями
/// Сохраняет ID событий в UserDefaults для персистентного хранения
class FavoritesManager: ObservableObject {
    
    // Singleton для использования по всему приложению
    static let shared = FavoritesManager()
    private init() {
        loadFavorites()
        // Временно: очистим избранное для отладки
        // Уберите эту строку после исправления проблемы
        // clearAllFavorites()
    }
    
    // MARK: - Properties
    private let favoritesKey = "favoriteEventIDs"
    
    // Опубликованное свойство для автообновления UI
    @Published private(set) var favoriteEventIDs: Set<Int> = []
    
    // MARK: - Public Methods
    
    /// Добавляет или удаляет событие из избранного
    /// - Parameter eventID: ID спортивного события
    func toggleFavorite(eventID: Int) {
        let wasAdded = !favoriteEventIDs.contains(eventID)
        
        if favoriteEventIDs.contains(eventID) {
            favoriteEventIDs.remove(eventID)
        } else {
            favoriteEventIDs.insert(eventID)
        }
        
        // Логируем изменение избранного
        Analytics.logEvent(wasAdded ? "favorite_added" : "favorite_removed", parameters: [
            "event_id": eventID,
            "total_favorites": favoriteEventIDs.count
        ])
        
        saveFavorites()
        
        print("💙 [Favorites] Событие \(eventID) \(wasAdded ? "добавлено в" : "удалено из") избранного")
        print("📊 [Analytics] Logged: \(wasAdded ? "favorite_added" : "favorite_removed"), total: \(favoriteEventIDs.count)")
    }
    
    /// Проверяет, находится ли событие в избранном
    /// - Parameter eventID: ID спортивного события
    /// - Returns: true если событие в избранном
    func isFavorite(eventID: Int) -> Bool {
        let result = favoriteEventIDs.contains(eventID)
        if result {
            print("💙 [Favorites] Событие \(eventID) НАЙДЕНО в избранном из списка: \(favoriteEventIDs)")
        }
        return result
    }
    
    /// Возвращает количество избранных событий
    var favoritesCount: Int {
        return favoriteEventIDs.count
    }
    
    /// Получает избранные события из переданного списка
    /// - Parameter allEvents: Полный список событий
    /// - Returns: Массив избранных событий
    func getFavoriteEvents(from allEvents: [SportEvent]) -> [SportEvent] {
        return allEvents.filter { favoriteEventIDs.contains($0.id) }
    }
    
    /// Очищает все избранные события
    func clearAllFavorites() {
        favoriteEventIDs.removeAll()
        saveFavorites()
        print("🗑️ [Favorites] Все избранные события удалены")
    }
    
    // MARK: - Private Methods
    
    /// Сохраняет избранные ID в UserDefaults
    private func saveFavorites() {
        let favoriteArray = Array(favoriteEventIDs)
        UserDefaults.standard.set(favoriteArray, forKey: favoritesKey)
        
        // Принудительная синхронизация для надежности
        UserDefaults.standard.synchronize()
    }
    
    /// Загружает избранные ID из UserDefaults
    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] {
            favoriteEventIDs = Set(savedFavorites)
            print("✅ [Favorites] Загружено \(favoriteEventIDs.count) избранных событий: \(favoriteEventIDs)")
        } else {
            favoriteEventIDs = []
            print("📂 [Favorites] Избранные события не найдены - создан пустой список")
        }
    }
}

// MARK: - Favorites Status
/// Статус избранного для отображения в UI
struct FavoritesStatus {
    let count: Int
    let isEmpty: Bool
    
    var description: String {
        if isEmpty {
            return "Нет избранных событий"
        } else {
            return "\(count) избранных событий"
        }
    }
}

extension FavoritesManager {
    
    /// Возвращает текущий статус избранного для UI
    var status: FavoritesStatus {
        return FavoritesStatus(
            count: favoritesCount,
            isEmpty: favoriteEventIDs.isEmpty
        )
    }
}