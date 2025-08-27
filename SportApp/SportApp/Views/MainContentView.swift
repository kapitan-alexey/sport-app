import SwiftUI

// MARK: - Main Content View
struct MainContentView: View {
    @ObservedObject var eventsManager: EventsDataManager
    let filteredEvents: [SportEvent]
    
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
                    eventsManager: eventsManager
                )
            }
        }
    }
}

// MARK: - Events List View
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
                eventsManager.refreshEvents()
            }
        }
    }
}

// MARK: - Data Status Banner
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