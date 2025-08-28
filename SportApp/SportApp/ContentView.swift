import SwiftUI

// MARK: - Main Content View with Enhanced Caching
struct ContentView: View {
    @StateObject private var eventsManager = EventsDataManager()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var filterCriteria = FilterCriteria()
    @State private var showingCacheSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Основной контент
            if selectedTab == 0 {
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
            } else {
                FavoritesView()
            }
            
            // Кастомный TabBar
            HStack {
                Spacer()
                
                Button(action: {
                    selectedTab = 0
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundColor(selectedTab == 0 ? Color(red: 18/255, green: 250/255, blue: 210/255) : .gray)
                        Text("События")
                            .font(.caption)
                            .foregroundColor(selectedTab == 0 ? Color(red: 18/255, green: 250/255, blue: 210/255) : .gray)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    selectedTab = 1
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.title2)
                            .foregroundColor(selectedTab == 1 ? Color(red: 18/255, green: 250/255, blue: 210/255) : .gray)
                        Text("Избранное")
                            .font(.caption)
                            .foregroundColor(selectedTab == 1 ? Color(red: 18/255, green: 250/255, blue: 210/255) : .gray)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
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
    
    /// Настраивает внешний вид TabBar (теперь не используется, но оставлено для совместимости)
    private func setupTabBarAppearance() {
        // Убираем стандартный TabBar, так как используем кастомный
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
    @StateObject private var eventsManager = EventsDataManager()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if favoriteEvents.isEmpty {
                    // Пустое состояние
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Нет избранных событий")
                            .font(.appTitle2)
                            .foregroundColor(.white)
                        
                        Text("Добавьте события в избранное, нажав на ♡ в описании события")
                            .font(.appBody)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    // Список избранных событий
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favoriteEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Избранное")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Загружаем события если их еще нет
                if eventsManager.events.isEmpty {
                    Task {
                        await eventsManager.loadEvents()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Computed Properties
    
    /// Получает избранные события из загруженных данных
    private var favoriteEvents: [SportEvent] {
        return favoritesManager.getFavoriteEvents(from: eventsManager.events)
    }
}

#Preview {
    ContentView()
}
