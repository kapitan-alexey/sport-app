import Foundation

// MARK: - Sports Events Cache Manager
/// Менеджер для кеширования данных о спортивных событиях на диск
/// Обеспечивает offline доступность и быструю загрузку при старте приложения
class SportsEventsCache {
    
    // Singleton для использования по всему приложению
    static let shared = SportsEventsCache()
    private init() {}
    
    // MARK: - Constants
    private let cacheFileName = "sports_events_cache.json"
    private let lastUpdateKey = "lastSportsEventsUpdate"
    private let cacheValidityDuration: TimeInterval = 3600 // 1 час
    
    // MARK: - Core Caching Methods
    
    /// Сохраняет события в постоянный кеш на диске
    /// - Parameter events: Массив событий для кеширования
    func saveEvents(_ events: [SportEvent]) {
        do {
            // Кодируем события в JSON формат
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            
            // Получаем URL файла в Caches Directory
            let cacheURL = getCacheFileURL()
            
            // Записываем данные в файл
            try data.write(to: cacheURL)
            
            // Сохраняем время последнего обновления в UserDefaults
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            
            print("✅ [Cache] Сохранено \(events.count) событий в кеш")
            logCacheInfo()
            
        } catch {
            print("❌ [Cache] Ошибка сохранения в кеш: \(error.localizedDescription)")
        }
    }
    
    /// Загружает события из кеша
    /// - Returns: Массив событий или nil, если кеш недоступен
    func loadCachedEvents() -> [SportEvent]? {
        do {
            let cacheURL = getCacheFileURL()
            
            // Проверяем существование файла кеша
            guard FileManager.default.fileExists(atPath: cacheURL.path) else {
                print("📂 [Cache] Файл кеша не найден")
                return nil
            }
            
            // Читаем данные из файла
            let data = try Data(contentsOf: cacheURL)
            
            // Декодируем JSON обратно в события
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let events = try decoder.decode([SportEvent].self, from: data)
            
            print("✅ [Cache] Загружено \(events.count) событий из кеша")
            return events
            
        } catch {
            print("❌ [Cache] Ошибка загрузки из кеша: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache Validation
    
    /// Проверяет актуальность кеша
    /// - Parameter maxAge: Максимальный возраст кеша в секундах (по умолчанию 1 час)
    /// - Returns: true если кеш актуален, false если устарел
    func isCacheValid(maxAge: TimeInterval = 3600) -> Bool {
        guard let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date else {
            print("⏰ [Cache] Нет информации о последнем обновлении")
            return false
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        let isValid = timeSinceUpdate < maxAge
        
        if isValid {
            let minutes = Int(timeSinceUpdate / 60)
            print("✅ [Cache] Кеш актуален (обновлен \(minutes) мин. назад)")
        } else {
            let hours = Int(timeSinceUpdate / 3600)
            print("⏰ [Cache] Кеш устарел (обновлен \(hours) ч. назад)")
        }
        
        return isValid
    }
    
    /// Возвращает дату последнего обновления кеша
    func getLastUpdateDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
    }
    
    // MARK: - Cache Management
    
    /// Полностью очищает кеш
    func clearCache() {
        do {
            let cacheURL = getCacheFileURL()
            
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                try FileManager.default.removeItem(at: cacheURL)
                UserDefaults.standard.removeObject(forKey: lastUpdateKey)
                print("🗑️ [Cache] Кеш полностью очищен")
            } else {
                print("📂 [Cache] Файл кеша уже отсутствует")
            }
        } catch {
            print("❌ [Cache] Ошибка очистки кеша: \(error.localizedDescription)")
        }
    }
    
    /// Возвращает размер файла кеша в байтах
    func getCacheSize() -> Int64 {
        do {
            let cacheURL = getCacheFileURL()
            let attributes = try FileManager.default.attributesOfItem(atPath: cacheURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Возвращает читаемый размер кеша
    func getFormattedCacheSize() -> String {
        let sizeInBytes = getCacheSize()
        
        if sizeInBytes < 1024 {
            return "\(sizeInBytes) B"
        } else if sizeInBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(sizeInBytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(sizeInBytes) / (1024.0 * 1024.0))
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Возвращает URL файла кеша в Caches Directory
    private func getCacheFileURL() -> URL {
        // Получаем путь к Caches Directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory,
                                                     in: .userDomainMask).first!
        
        // Создаем подпапку для нашего приложения
        let appCacheDirectory = cacheDirectory.appendingPathComponent("SportsEventsApp")
        
        // Создаем папку если её нет
        try? FileManager.default.createDirectory(at: appCacheDirectory,
                                               withIntermediateDirectories: true)
        
        return appCacheDirectory.appendingPathComponent(cacheFileName)
    }
    
    /// Выводит информацию о состоянии кеша в консоль (для отладки)
    private func logCacheInfo() {
        let size = getFormattedCacheSize()
        let lastUpdate = getLastUpdateDate()
        
        print("📊 [Cache] Размер: \(size)")
        if let update = lastUpdate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            print("📊 [Cache] Последнее обновление: \(formatter.string(from: update))")
        }
    }
}

// MARK: - Cache Loading Strategy
/// Стратегия загрузки данных с кешированием
enum CacheLoadingStrategy {
    case cacheFirst       // Сначала кеш, затем API (рекомендуется)
    case apiFirst         // Сначала API, затем кеш при ошибке
    case cacheOnly        // Только кеш (offline режим)
    case apiOnly          // Только API (игнорировать кеш)
}

// MARK: - Cache Result
/// Результат операции с кешем
enum CacheResult<T> {
    case success(T)
    case failure(Error)
    case empty
}

// MARK: - Cache Status
/// Статус кеша для UI
struct CacheStatus {
    let hasCache: Bool
    let isValid: Bool
    let lastUpdate: Date?
    let size: String
    let eventCount: Int
    
    var description: String {
        if !hasCache {
            return "Кеш пуст"
        }
        
        let validity = isValid ? "актуален" : "устарел"
        return "\(eventCount) событий, \(validity), \(size)"
    }
}

extension SportsEventsCache {
    
    /// Возвращает текущий статус кеша для отображения в UI
    func getCacheStatus() -> CacheStatus {
        let events = loadCachedEvents()
        let hasCache = events != nil
        let isValid = isCacheValid()
        let lastUpdate = getLastUpdateDate()
        let size = getFormattedCacheSize()
        let eventCount = events?.count ?? 0
        
        return CacheStatus(
            hasCache: hasCache,
            isValid: isValid,
            lastUpdate: lastUpdate,
            size: size,
            eventCount: eventCount
        )
    }
}
