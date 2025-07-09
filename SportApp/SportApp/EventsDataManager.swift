import Foundation
import SwiftUI
import Combine

// MARK: - Events Data Manager with Caching
/// Основной менеджер данных для спортивных событий
/// Реализует паттерн MVVM и управляет состоянием между UI, кешем и API
/// Обеспечивает мгновенную загрузку из кеша и автоматическое обновление данных
@MainActor
class EventsDataManager: ObservableObject {
    
    // MARK: - Published Properties для SwiftUI
    /// Основной массив событий, отображаемый в UI
    @Published var events: [SportEvent] = []
    
    /// Индикатор загрузки для показа ProgressView
    @Published var isLoading = false
    
    /// Сообщение об ошибке для показа в UI
    @Published var errorMessage: String?
    
    /// Статус кеша для отображения в настройках или debug info
    @Published var cacheStatus: CacheStatus = CacheStatus(
        hasCache: false, isValid: false, lastUpdate: nil, size: "0 B", eventCount: 0
    )
    
    /// Индикатор того, что данные загружены из кеша (для показа соответствующих UI элементов)
    @Published var isDataFromCache = false
    
    /// Индикатор фонового обновления данных
    @Published var isBackgroundRefreshing = false
    
    // MARK: - Private Properties
    private let apiService = ApiService.shared
    private let cache = SportsEventsCache.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupNotificationObservers()
        updateCacheStatus()
    }
    
    // MARK: - Main Loading Methods
    
    /// Основной метод загрузки событий с умной стратегией кеширования
    /// Автоматически выбирает оптимальную стратегию в зависимости от ситуации
    func loadEvents() async {
        print("🚀 [Manager] Начинаем загрузку событий")
        
        // Если это первая загрузка, показываем индикатор
        if events.isEmpty {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Используем cache-first стратегию для оптимального UX
            let loadedEvents = try await apiService.loadEventsWithCache(strategy: .cacheFirst)
            
            // Обновляем UI на главном потоке
            await updateEventsOnMainThread(loadedEvents, fromCache: cache.isCacheValid())
            
            print("✅ [Manager] События успешно загружены: \(loadedEvents.count)")
            
        } catch {
            await handleLoadingError(error)
        }
        
        isLoading = false
        updateCacheStatus()
    }
    
    /// Принудительное обновление данных (pull-to-refresh)
    /// Игнорирует кеш и всегда загружает свежие данные из API
    func refreshEvents() {
        print("🔄 [Manager] Принудительное обновление событий")
        
        Task {
            isBackgroundRefreshing = true
            errorMessage = nil
            
            do {
                // Используем API-first стратегию для принудительного обновления
                let freshEvents = try await apiService.loadEventsWithCache(strategy: .apiFirst)
                await updateEventsOnMainThread(freshEvents, fromCache: false)
                
                print("✅ [Manager] События обновлены: \(freshEvents.count)")
                
            } catch {
                await handleRefreshError(error)
            }
            
            isBackgroundRefreshing = false
            updateCacheStatus()
        }
    }
    
    /// Быстрая загрузка из кеша для мгновенного отображения при старте приложения
    /// Используется в onAppear для показа данных без задержек
    func loadCachedEventsImmediately() {
        print("⚡ [Manager] Мгновенная загрузка из кеша")
        
        guard let cachedEvents = cache.loadCachedEvents() else {
            print("📂 [Manager] Кеш пуст, нужна полная загрузка")
            return
        }
        
        // Мгновенно показываем кешированные данные
        events = cachedEvents
        isDataFromCache = true
        errorMessage = nil
        updateCacheStatus()
        
        print("✅ [Manager] Показано \(cachedEvents.count) событий из кеша")
        
        // Если кеш устарел, запускаем фоновое обновление
        if !cache.isCacheValid() {
            print("🔄 [Manager] Кеш устарел, запускаем фоновое обновление")
            Task {
                await loadEvents()
            }
        }
    }
    
    // MARK: - Cache Management
    
    /// Очищает кеш и перезагружает данные
    func clearCacheAndReload() {
        print("🗑️ [Manager] Очистка кеша и перезагрузка")
        
        apiService.clearCache()
        events = []
        isDataFromCache = false
        updateCacheStatus()
        
        Task {
            await loadEvents()
        }
    }
    
    /// Показывает только кешированные данные (offline режим)
    func switchToOfflineMode() {
        print("📱 [Manager] Переключение в offline режим")
        
        Task {
            do {
                let offlineEvents = try await apiService.loadEventsWithCache(strategy: .cacheOnly)
                await updateEventsOnMainThread(offlineEvents, fromCache: true)
                
            } catch {
                await MainActor.run {
                    errorMessage = "Нет данных для offline режима"
                    events = []
                }
            }
            
            updateCacheStatus()
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Обновляет события на главном потоке и управляет состоянием UI
    private func updateEventsOnMainThread(_ newEvents: [SportEvent], fromCache: Bool) async {
        await MainActor.run {
            self.events = newEvents
            self.isDataFromCache = fromCache
            self.errorMessage = nil
            
            // Если данные из кеша, показываем соответствующий статус
            if fromCache && !cache.isCacheValid() {
                self.errorMessage = "Показаны данные из кеша (возможно, устарели)"
            }
        }
    }
    
    /// Обрабатывает ошибки загрузки с умным fallback на кеш
    private func handleLoadingError(_ error: Error) async {
        print("❌ [Manager] Ошибка загрузки: \(error.localizedDescription)")
        
        await MainActor.run {
            // Если есть кешированные данные, показываем их вместо ошибки
            if let cachedEvents = cache.loadCachedEvents(), !cachedEvents.isEmpty {
                self.events = cachedEvents
                self.isDataFromCache = true
                self.errorMessage = "Не удалось обновить данные. Показаны данные из кеша."
                
                print("✅ [Manager] Показываем кешированные данные вместо ошибки")
                
            } else {
                // Нет кеша - показываем ошибку
                self.events = []
                self.isDataFromCache = false
                self.errorMessage = error.localizedDescription
                
                print("❌ [Manager] Нет кеша, показываем ошибку пользователю")
            }
        }
    }
    
    /// Обрабатывает ошибки принудительного обновления
    private func handleRefreshError(_ error: Error) async {
        print("⚠️ [Manager] Ошибка обновления: \(error.localizedDescription)")
        
        await MainActor.run {
            // При ошибке refresh оставляем текущие данные, но показываем предупреждение
            if !events.isEmpty {
                self.errorMessage = "Не удалось обновить. Показаны прежние данные."
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Обновляет статус кеша для отображения в UI
    private func updateCacheStatus() {
        cacheStatus = cache.getCacheStatus()
    }
    
    /// Настраивает наблюдателей за уведомлениями
    private func setupNotificationObservers() {
        // Слушаем уведомления о фоновом обновлении данных
        NotificationCenter.default.publisher(for: .sportsEventsUpdatedInBackground)
            .compactMap { $0.object as? [SportEvent] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedEvents in
                self?.handleBackgroundUpdate(updatedEvents)
            }
            .store(in: &cancellables)
    }
    
    /// Обрабатывает фоновое обновление данных
    private func handleBackgroundUpdate(_ updatedEvents: [SportEvent]) {
        print("🔄 [Manager] Получено фоновое обновление: \(updatedEvents.count) событий")
        
        // Тихо обновляем данные без показа индикаторов загрузки
        events = updatedEvents
        isDataFromCache = false
        updateCacheStatus()
        
        // Можно показать subtle уведомление о том, что данные обновились
        if errorMessage?.contains("кеша") == true {
            errorMessage = nil // Убираем сообщение о устаревших данных
        }
    }
    
    // MARK: - Utility Methods
    
    /// Возвращает количество событий в кеше
    var cachedEventsCount: Int {
        cache.loadCachedEvents()?.count ?? 0
    }
    
    /// Проверяет, актуален ли кеш
    var isCacheValid: Bool {
        cache.isCacheValid()
    }
    
    /// Возвращает дату последнего обновления кеша
    var lastCacheUpdate: Date? {
        cache.getLastUpdateDate()
    }
    
    /// Возвращает читаемое описание состояния данных
    var dataSourceDescription: String {
        if isLoading {
            return "Загрузка..."
        } else if isDataFromCache {
            return isCacheValid ? "Данные из кеша (актуальные)" : "Данные из кеша (могут быть устаревшими)"
        } else {
            return "Свежие данные с сервера"
        }
    }
    
    // MARK: - Filter Support Methods
    
    /// Получение уникальных городов для FilterView
    var availableCities: [String] {
        Array(Set(events.map { $0.cityName })).sorted()
    }
    
    /// Получение уникальных видов спорта для FilterView
    var availableSports: [String] {
        let allSports = events.flatMap { $0.sports.map { $0.name } }
        return Array(Set(allSports)).sorted()
    }
}

// MARK: - Filter Criteria (если у вас есть фильтрация)
struct EventFilterCriteria {
    var selectedSports: Set<String> = []
    var selectedCities: Set<String> = []
    var dateRange: DateRange?
    var showOnlyAvailableForRegistration: Bool = false
    
    struct DateRange {
        let from: Date
        let to: Date
    }
    
    /// Проверяет, есть ли активные фильтры
    var hasActiveFilters: Bool {
        return !selectedSports.isEmpty ||
               !selectedCities.isEmpty ||
               dateRange != nil ||
               showOnlyAvailableForRegistration
    }
    
    /// Проверяет, соответствует ли событие критериям фильтрации
    func matches(event: SportEvent) -> Bool {
        // Фильтр по видам спорта
        if !selectedSports.isEmpty {
            let eventSports = Set(event.sports.map { $0.name.lowercased() })
            let filterSports = Set(selectedSports.map { $0.lowercased() })
            if eventSports.isDisjoint(with: filterSports) {
                return false
            }
        }
        
        // Фильтр по городам
        if !selectedCities.isEmpty {
            if !selectedCities.contains(event.cityName) {
                return false
            }
        }
        
        // Фильтр по датам
        if let dateRange = dateRange {
            if event.date < dateRange.from || event.date > dateRange.to {
                return false
            }
        }
        
        // Фильтр по доступности регистрации
        if showOnlyAvailableForRegistration && !event.canRegister {
            return false
        }
        
        return true
    }
}

// MARK: - Debug Extensions для разработки
extension EventsDataManager {
    
    /// Возвращает детальную информацию о состоянии для debug консоли
    var debugInfo: String {
        let cacheStatus = cache.getCacheStatus()
        
        return """
        📊 EventsDataManager Debug Info:
        - События в памяти: \(events.count)
        - Загрузка: \(isLoading ? "Да" : "Нет")
        - Фоновое обновление: \(isBackgroundRefreshing ? "Да" : "Нет")
        - Данные из кеша: \(isDataFromCache ? "Да" : "Нет")
        - Ошибка: \(errorMessage ?? "Нет")
        - Кеш актуален: \(cacheStatus.isValid ? "Да" : "Нет")
        - Размер кеша: \(cacheStatus.size)
        - События в кеше: \(cacheStatus.eventCount)
        - Последнее обновление: \(lastCacheUpdate?.description ?? "Никогда")
        """
    }
    
    /// Принтит debug информацию в консоль
    func printDebugInfo() {
        print(debugInfo)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Уведомление о том, что события обновились в фоновом режиме
    static let sportsEventsUpdatedInBackground = Notification.Name("sportsEventsUpdatedInBackground")
}
