import SwiftUI

// MARK: - Main Content View
struct MainContentView: View {
    @ObservedObject var eventsManager: EventsDataManager
    let filteredEvents: [SportEvent]
    @Binding var isKeyboardActive: Bool
    
    var body: some View {
        Group {
            if eventsManager.isLoading && eventsManager.events.isEmpty {
                LoadingView()
            } else if let errorMessage = eventsManager.errorMessage, eventsManager.events.isEmpty {
                ErrorView(
                    message: errorMessage,
                    cacheStatus: eventsManager.cacheStatus
                ) {
                    Task {
                        await eventsManager.loadEvents()
                    }
                }
            } else {
                EventsListView(
                    events: filteredEvents,
                    eventsManager: eventsManager,
                    isKeyboardActive: $isKeyboardActive
                )
            }
        }
    }
}

// MARK: - Events List View
struct EventsListView: View {
    let events: [SportEvent]
    @ObservedObject var eventsManager: EventsDataManager
    @Binding var isKeyboardActive: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Список событий или сообщение об отсутствии результатов
            if events.isEmpty && !eventsManager.events.isEmpty {
                // Показываем сообщение о том, что фильтр не дал результатов
                NoFilterResultsView()
                    .onTapGesture {
                        // Скрыть клавиатуру при нажатии на экран "ничего не найдено"
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            } else {
                ZStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(events) { event in
                                    EventCardView(event: event, isKeyboardActive: $isKeyboardActive)
                                        .padding(.horizontal, 8)
                                }
                            }
                            .padding(.top, 0)
                            .padding(.bottom, 100)
                            .background(
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Скрыть клавиатуру при нажатии на фон между карточками
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                            )
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .simultaneousGesture(
                            DragGesture().onChanged { _ in
                                // Скрыть клавиатуру при начале прокрутки
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        )
                    }
                    .refreshable {
                        eventsManager.refreshEvents()
                    }
                    
                    // Индикатор загрузки с текстом для pull-to-refresh
                    if eventsManager.isLoading && !eventsManager.events.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.0, green: 0.8, blue: 0.7)))
                                .scaleEffect(1.2)
                            
                            Text("Загрузка событий")
                                .font(.callout)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - No Filter Results View
struct NoFilterResultsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Ничего не найдено")
                    .font(.appEventTitle)
                    .foregroundColor(.white)
                
                Text("Попробуйте изменить параметры фильтра")
                    .font(.appSubheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}