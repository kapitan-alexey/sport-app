import SwiftUI

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
                        .font(.appTitle3)
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
                    .font(.appCallout)

                TextField("Поиск событий...", text: $searchText)
                    .foregroundColor(.primary)
                    .font(.appCallout)
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
                        .font(.appHeadline)
                    
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