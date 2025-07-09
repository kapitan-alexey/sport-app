import SwiftUI

// MARK: - Main Content View with Enhanced Caching
struct ContentView: View {
    @StateObject private var eventsManager = EventsDataManager()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var filterCriteria = FilterCriteria()
    @State private var showingCacheSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // События таба
            NavigationView {
                ZStack {
                    Color.black.ignoresSafeArea(.all)

                    VStack(spacing: 0) {
                        // Заголовок с индикаторами кеша
                        HeaderView(
                            searchText: $searchText,
                            filterCriteria: $filterCriteria,
                            eventsManager: eventsManager,
                            showingCacheSettings: $showingCacheSettings
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        Spacer().frame(height: 16)

                        // Основной контент с умной логикой загрузки
                        MainContentView(
                            eventsManager: eventsManager,
                            filteredEvents: filteredEvents
                        )
                    }
                }
            }
            .tabItem {
                Image(systemName: "calendar.badge.plus")
                Text("События")
            }
            .tag(0)

            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Календарь")
                }
                .tag(1)

            FavoritesView()
                .tabItem {
                    Image(systemName: "star")
                    Text("Избранное")
                }
                .tag(2)
        }
        .accentColor(Color(red: 0.0, green: 0.8, blue: 0.7))
        .preferredColorScheme(.dark)
        .onAppear {
            setupTabBarAppearance()
            
            // ✅ Умная логика первичной загрузки
            handleInitialLoad()
        }
        .sheet(isPresented: $showingCacheSettings) {
            CacheSettingsView(eventsManager: eventsManager)
        }
    }

    // MARK: - Computed Properties
    
    /// Фильтрует события по поисковому запросу и критериям фильтрации
    private var filteredEvents: [SportEvent] {
        var result = eventsManager.events

        // Поиск по тексту
        if !searchText.isEmpty {
            result = result.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.cityName.localizedCaseInsensitiveContains(searchText) ||
                event.sportName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Применение фильтров
        result = result.filter { event in
            filterCriteria.matches(event: event)
        }

        return result
    }
    
    // MARK: - Private Methods
    
    /// Настраивает внешний вид TabBar
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    /// Обрабатывает первичную загрузку данных при запуске приложения
    private func handleInitialLoad() {
        // Сначала пытаемся мгновенно показать кешированные данные
        eventsManager.loadCachedEventsImmediately()
        
        // Затем запускаем полную загрузку для обновления данных
        Task {
            await eventsManager.loadEvents()
        }
    }
}

// MARK: - Main Content View
/// Основной контент с событиями, обработкой состояний загрузки и ошибок
struct MainContentView: View {
    @ObservedObject var eventsManager: EventsDataManager
    let filteredEvents: [SportEvent]
    
    var body: some View {
        Group {
            if eventsManager.isLoading && eventsManager.events.isEmpty {
                // Показываем загрузку только если нет данных для отображения
                LoadingView()
            } else if let errorMessage = eventsManager.errorMessage, eventsManager.events.isEmpty {
                // Показываем ошибку только если нет данных для отображения
                ErrorView(
                    message: errorMessage,
                    cacheStatus: eventsManager.cacheStatus
                ) {
                    Task {
                        await eventsManager.loadEvents()
                    }
                }
            } else {
                // Показываем события с индикаторами состояния
                EventsListView(
                    events: filteredEvents,
                    eventsManager: eventsManager
                )
            }
        }
    }
}

// MARK: - Events List View
/// Список событий с поддержкой pull-to-refresh и индикаторов состояния
struct EventsListView: View {
    let events: [SportEvent]
    @ObservedObject var eventsManager: EventsDataManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Индикатор состояния данных
            if eventsManager.isDataFromCache || eventsManager.isBackgroundRefreshing {
                DataStatusBanner(eventsManager: eventsManager)
            }
            
            // Список событий
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(events) { event in
                        EventCardView(event: event)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.top, 0)
                .padding(.bottom, 100)
            }
            .refreshable {
                // Pull-to-refresh обновляет данные принудительно
                eventsManager.refreshEvents()
            }
        }
    }
}

// MARK: - Data Status Banner
/// Баннер с информацией о состоянии данных (кеш, обновление и т.д.)
struct DataStatusBanner: View {
    @ObservedObject var eventsManager: EventsDataManager
    
    var body: some View {
        HStack {
            if eventsManager.isBackgroundRefreshing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.0, green: 0.8, blue: 0.7)))
                    .scaleEffect(0.8)
                
                Text("Обновление данных...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            } else if eventsManager.isDataFromCache {
                Image(systemName: eventsManager.isCacheValid ? "checkmark.circle" : "clock.circle")
                    .foregroundColor(eventsManager.isCacheValid ? .green : .orange)
                
                Text(eventsManager.dataSourceDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Enhanced Header View
struct HeaderView: View {
    @Binding var searchText: String
    @Binding var filterCriteria: FilterCriteria
    @ObservedObject var eventsManager: EventsDataManager
    @Binding var showingCacheSettings: Bool
    @State private var showingFilters = false

    var body: some View {
        HStack(spacing: 12) {
            // Кнопка фильтров с индикатором
            ZStack {
                Button(action: {
                    showingFilters.toggle()
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                        .font(.title2)
                }

                if filterCriteria.hasActiveFilters {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 10, y: -10)
                }
            }

            // Поле поиска
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))

                TextField("Поиск событий...", text: $searchText)
                    .foregroundColor(.primary)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.1))
            )

            // Кнопка настроек кеша (для debug и настроек)
            Button(action: {
                showingCacheSettings.toggle()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.8, blue: 0.7))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: eventsManager.cacheStatus.hasCache ? "person.fill" : "person")
                        .foregroundColor(.black)
                        .font(.system(size: 18))
                    
                    // Индикатор состояния кеша
                    if eventsManager.cacheStatus.hasCache {
                        Circle()
                            .fill(eventsManager.cacheStatus.isValid ? .green : .orange)
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(filterCriteria: $filterCriteria, eventsManager: eventsManager)
        }
    }
}

// MARK: - Enhanced Event Card View
struct EventCardView: View {
    let event: SportEvent
    @State private var showingDetail = false

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(spacing: 0) {
                // Изображение с улучшенным кешированием
                CachedAsyncImage(
                    url: URL(string: event.fullPhotoMainURL ?? "")
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.purple.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            Text("Загрузка...")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                } failure: {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.4),
                                Color.blue.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Изображение недоступно")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
                .frame(height: 140)
                .clipped()

                // Информация о событии
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Text("\(event.cityName) • \(event.formattedDate)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    SportIconsView(event: event)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            }
            .background(Color.black)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingDetail) {
            EventDetailView(event: event)
        }
    }
}

// MARK: - Enhanced Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.0, green: 0.8, blue: 0.7)))
                .scaleEffect(1.5)
            
            Text("Загрузка событий...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Подключение к серверу...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Enhanced Error View
struct ErrorView: View {
    let message: String
    let cacheStatus: CacheStatus
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Ошибка загрузки")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Информация о кеше
            if cacheStatus.hasCache {
                VStack(spacing: 8) {
                    Text("💾 В кеше: \(cacheStatus.eventCount) событий")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Размер: \(cacheStatus.size)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Повторить")
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 0.0, green: 0.8, blue: 0.7))
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Cache Settings View
/// Экран настроек кеша для управления и отладки
struct CacheSettingsView: View {
    @ObservedObject var eventsManager: EventsDataManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Статистика кеша
                VStack(alignment: .leading, spacing: 12) {
                    Text("Состояние кеша")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("События:")
                            Spacer()
                            Text("\(eventsManager.cacheStatus.eventCount)")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Размер:")
                            Spacer()
                            Text(eventsManager.cacheStatus.size)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Статус:")
                            Spacer()
                            Text(eventsManager.cacheStatus.isValid ? "Актуален" : "Устарел")
                                .foregroundColor(eventsManager.cacheStatus.isValid ? .green : .orange)
                        }
                        
                        if let lastUpdate = eventsManager.lastCacheUpdate {
                            HStack {
                                Text("Обновлен:")
                                Spacer()
                                Text(DateFormatter.shortDateTime.string(from: lastUpdate))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .font(.body)
                    .foregroundColor(.white)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Действия с кешем
                VStack(spacing: 12) {
                    Button("Обновить данные") {
                        eventsManager.refreshEvents()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Очистить кеш") {
                        eventsManager.clearCacheAndReload()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Offline режим") {
                        eventsManager.switchToOfflineMode()
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Настройки кеша")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.black)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.0, green: 0.8, blue: 0.7))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Helper Extensions
extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Sport Icons and Other Views
struct SportIconsView: View {
    let event: SportEvent

    var body: some View {
        HStack(spacing: 6) {
            ForEach(event.sports, id: \.id) { sport in
                SportIconView(sport: sport, size: 26)
            }
        }
    }
}

struct SportIconView: View {
    let sport: Sport
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(red: 18/255, green: 250/255, blue: 210/255))
            .frame(width: size, height: size)
            .overlay(
                Image(customIconName(for: sport.name))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(.black)
            )
    }
    
    private func customIconName(for sportName: String) -> String {
        switch sportName.lowercased() {
        case "бег":
            return "running_icon"
        case "плавание":
            return "swimming_icon"
        case "велоспорт":
            return "cycling_icon"
        case "автоспорт":
            return "motorsport_icon"
        case "триатлон":
            return "triathlon_icon"
        default:
            return "default_sport_icon"
        }
    }
}

struct CalendarView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Календарь")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Здесь будет календарь событий")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

struct FavoritesView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Избранное")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Здесь будут избранные события")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
