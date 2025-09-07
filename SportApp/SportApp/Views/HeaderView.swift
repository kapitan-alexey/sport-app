import SwiftUI

// MARK: - Enhanced Header View
struct HeaderView: View {
    @Binding var searchText: String
    @Binding var filterCriteria: FilterCriteria
    @ObservedObject var eventsManager: EventsDataManager
    @Binding var showingCacheSettings: Bool
    @Binding var showingSettings: Bool
    @Binding var isKeyboardActive: Bool
    @State private var showingFilters = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Кнопка фильтров с индикатором
            ZStack {
                Button(action: {
                    showingFilters.toggle()
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                        .font(.appTitle2)
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
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .focused($isSearchFocused)
                    .onChange(of: isSearchFocused) { focused in
                        isKeyboardActive = focused
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )

            // Кнопка настроек
            Button(action: {
                showingSettings.toggle()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                        .font(.appHeadline)
                }
            }
        }
        .fullScreenCover(isPresented: $showingFilters) {
            FilterView(filterCriteria: $filterCriteria, eventsManager: eventsManager)
        }
    }
}