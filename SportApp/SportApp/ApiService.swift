import Foundation
import Combine
import UIKit

// MARK: - Enhanced API Service with Caching
/// Сервис для работы с API и кешированием данных о спортивных событиях
/// Реализует стратегию "Cache-First" для оптимального пользовательского опыта
class ApiService: ObservableObject {
    static let shared = ApiService()
    
    private let baseURL = "http://192.168.0.136:8000"
    private let session: URLSession
    private let cache = SportsEventsCache.shared
    
    // MARK: - Published Properties для SwiftUI
    @Published var isLoading = false
    @Published var lastErrorMessage: String?
    
    private init() {
        // Создаем конфигурацию с оптимизированными настройками
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0      // 10 секунд на API запросы
        config.timeoutIntervalForResource = 20.0     // 20 секунд общий таймаут
        config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Main Loading Method with Cache-First Strategy
    
    /// Основной метод загрузки событий с кеш-first стратегией
    /// Этот метод объединяет кеширование и API в единый простой интерфейс
    /// - Parameter strategy: Стратегия загрузки (по умолчанию cache-first)
    /// - Returns: Массив событий
    func loadEventsWithCache(strategy: CacheLoadingStrategy = .cacheFirst) async throws -> [SportEvent] {
        print("🚀 [API] Начинаем загрузку событий со стратегией: \(strategy)")
        
        switch strategy {
        case .cacheFirst:
            return try await loadWithCacheFirstStrategy()
        case .apiFirst:
            return try await loadWithApiFirstStrategy()
        case .cacheOnly:
            return try await loadCacheOnly()
        case .apiOnly:
            return try await fetchEventsFromAPI()
        }
    }
    
    // MARK: - Cache-First Strategy (Recommended)
    
    /// Реализует стратегию "кеш-первый": быстро возвращает кешированные данные,
    /// затем тихо обновляет их из API в фоновом режиме
    private func loadWithCacheFirstStrategy() async throws -> [SportEvent] {
        print("📋 [API] Стратегия: Cache-First")
        
        // Шаг 1: Проверяем кеш для мгновенного отображения
        if let cachedEvents = cache.loadCachedEvents() {
            print("✅ [API] Найдены кешированные события: \(cachedEvents.count)")
            
            // Если кеш актуален, возвращаем его без API запроса
            if cache.isCacheValid() {
                print("⚡ [API] Кеш актуален, API запрос не нужен")
                return cachedEvents
            }
            
            // Кеш устарел - запускаем фоновое обновление, но возвращаем старые данные
            print("🔄 [API] Кеш устарел, запускаем фоновое обновление")
            Task {
                await updateCacheInBackground()
            }
            
            return cachedEvents
        }
        
        // Шаг 2: Кеша нет - загружаем из API
        print("📡 [API] Кеш пуст, загружаем из API")
        return try await fetchAndCacheEvents()
    }
    
    // MARK: - API-First Strategy
    
    /// Стратегия "API-первый": сначала пытается загрузить из API,
    /// при неудаче использует кеш как fallback
    private func loadWithApiFirstStrategy() async throws -> [SportEvent] {
        print("📋 [API] Стратегия: API-First")
        
        do {
            // Пытаемся загрузить свежие данные из API
            return try await fetchAndCacheEvents()
        } catch {
            print("⚠️ [API] API недоступен, пытаемся использовать кеш")
            
            // API недоступен - используем кеш как fallback
            if let cachedEvents = cache.loadCachedEvents() {
                print("✅ [API] Используем кешированные данные как fallback")
                lastErrorMessage = "Показаны данные из кеша (API недоступен)"
                return cachedEvents
            }
            
            // Ни API, ни кеш недоступны
            print("❌ [API] Ни API, ни кеш недоступны")
            throw APIError.noDataAvailable
        }
    }
    
    // MARK: - Cache-Only Strategy
    
    /// Стратегия "только-кеш": используется для offline режима
    private func loadCacheOnly() async throws -> [SportEvent] {
        print("📋 [API] Стратегия: Cache-Only (Offline режим)")
        
        guard let cachedEvents = cache.loadCachedEvents() else {
            throw APIError.noCacheAvailable
        }
        
        print("✅ [API] Возвращаем \(cachedEvents.count) событий из кеша")
        return cachedEvents
    }
    
    // MARK: - Core API Methods
    
    /// Загружает события из API и автоматически кеширует их
    private func fetchAndCacheEvents() async throws -> [SportEvent] {
        let events = try await fetchEventsFromAPI()
        
        // Сохраняем в кеш для будущего использования
        cache.saveEvents(events)
        
        return events
    }
    
    /// Базовый метод для запроса к API без кеширования
    func fetchEventsFromAPI() async throws -> [SportEvent] {
        await MainActor.run {
            isLoading = true
            lastErrorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        guard let url = URL(string: "\(baseURL)/events/") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData // Всегда получаем свежие данные
        
        do {
            print("📡 [API] Отправляем запрос к \(url)")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("📡 [API] Получен ответ: HTTP \(httpResponse.statusCode)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            let events = try decodeEventsResponse(data)
            print("✅ [API] Успешно декодировано \(events.count) событий")
            
            await MainActor.run {
                lastErrorMessage = nil
            }
            
            return events
            
        } catch let error as DecodingError {
            print("❌ [API] Ошибка декодирования: \(error)")
            await MainActor.run {
                lastErrorMessage = "Ошибка обработки данных с сервера"
            }
            throw APIError.decodingError(error.localizedDescription)
            
        } catch {
            print("❌ [API] Сетевая ошибка: \(error)")
            await MainActor.run {
                lastErrorMessage = "Не удалось подключиться к серверу"
            }
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Background Cache Update
    
    /// Обновляет кеш в фоновом режиме без влияния на UI
    /// Используется когда нужно тихо обновить устаревший кеш
    @MainActor
    private func updateCacheInBackground() async {
        do {
            print("🔄 [API] Начинаем фоновое обновление кеша")
            let freshEvents = try await fetchEventsFromAPI()
            cache.saveEvents(freshEvents)
            print("✅ [API] Кеш обновлен в фоновом режиме: \(freshEvents.count) событий")
            
            // Можно добавить уведомление для UI о том, что данные обновились
            NotificationCenter.default.post(
                name: .sportsEventsUpdatedInBackground,
                object: freshEvents
            )
            
        } catch {
            print("⚠️ [API] Фоновое обновление не удалось: \(error.localizedDescription)")
            // В фоновом режиме не показываем ошибки пользователю
        }
    }
    
    // MARK: - Cache Management Methods
    
    /// Принудительно обновляет кеш (для pull-to-refresh)
    func refreshCache() async throws -> [SportEvent] {
        print("🔄 [API] Принудительное обновление кеша")
        return try await fetchAndCacheEvents()
    }
    
    /// Очищает кеш (для настроек приложения)
    func clearCache() {
        cache.clearCache()
        print("🗑️ [API] Кеш очищен")
    }
    
    /// Возвращает статус кеша для отображения в UI
    func getCacheStatus() -> CacheStatus {
        return cache.getCacheStatus()
    }
    
    /// Метод для обратной совместимости со старым кодом
    /// Использует новую систему кеширования с cache-first стратегией
    func fetchEvents() async throws -> [SportEvent] {
        return try await loadEventsWithCache(strategy: .cacheFirst)
    }
    
    // MARK: - Helper Methods
    
    /// Декодирует ответ API в массив событий
    private func decodeEventsResponse(_ data: Data) throws -> [SportEvent] {
        let decoder = JSONDecoder()
        
        // Настраиваем декодирование дат для соответствия формату вашего API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try decoder.decode([SportEvent].self, from: data)
    }
}

// MARK: - Enhanced API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case networkError(String)
    case decodingError(String)
    case noDataAvailable      // Новый: ни API, ни кеш недоступны
    case noCacheAvailable     // Новый: кеш пуст в offline режиме
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL сервера"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        case .decodingError(let message):
            return "Ошибка обработки данных: \(message)"
        case .noDataAvailable:
            return "Данные недоступны (нет соединения и кеша)"
        case .noCacheAvailable:
            return "Данные не найдены в оффлайн режиме"
        }
    }
    
    /// Определяет, является ли ошибка критической (требует показа пользователю)
    var isCritical: Bool {
        switch self {
        case .noDataAvailable, .noCacheAvailable:
            return true
        default:
            return false
        }
    }
}

// MARK: - Image Loading Service (Enhanced)
class ImageLoadingService: ObservableObject {
    static let shared = ImageLoadingService()
    
    private let session: URLSession
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 100_000_000)
        
        self.session = URLSession(configuration: config)
        
        // Настройки кеша изображений
        cache.countLimit = 50
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    /// Синхронная проверка кеша изображений
    func getCachedImage(for urlString: String) -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        return cache.object(forKey: url as NSURL)
    }
    
    /// Асинхронная загрузка изображения с кешированием
    func loadImage(from urlString: String?) async -> UIImage? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        // Проверяем кеш
        if let cachedImage = cache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        // Загружаем изображение
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15",
                        forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }
            
            // Сохраняем в кеш
            cache.setObject(image, forKey: url as NSURL)
            return image
            
        } catch {
            return nil
        }
    }
}
