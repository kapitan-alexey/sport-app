import SwiftUI

// MARK: - Filter Data Model
struct FilterCriteria {
    var selectedCities: [String] = []
    var startDate: Date? = nil  // nil означает что фильтр дат не активен
    var endDate: Date? = nil    // nil означает что фильтр дат не активен
    var selectedSports: Set<String> = []
    
    func matches(event: SportEvent) -> Bool {
        // Проверка города
        if !selectedCities.isEmpty && !selectedCities.contains(event.cityName) {
            return false
        }
        
        // Проверка даты - только если установлены даты фильтра
        if let filterStartDate = startDate, let filterEndDate = endDate {
            if event.date < filterStartDate || event.date > filterEndDate {
                return false
            }
        }
        
        // Проверка вида спорта
        if !selectedSports.isEmpty {
            let hasMatchingSport = selectedSports.contains { selectedSport in
                event.sportName.localizedCaseInsensitiveContains(selectedSport) ||
                selectedSport.localizedCaseInsensitiveContains(event.sportName) ||
                event.sports.contains { sport in
                    sport.name.localizedCaseInsensitiveContains(selectedSport)
                }
            }
            if !hasMatchingSport {
                return false
            }
        }
        
        return true
    }
    
    // Проверяет, есть ли активные фильтры
    var hasActiveFilters: Bool {
        return !selectedCities.isEmpty || !selectedSports.isEmpty || startDate != nil || endDate != nil
    }
    
    // Сброс всех фильтров
    mutating func reset() {
        selectedCities = []
        selectedSports = []
        startDate = nil
        endDate = nil
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterCriteria: FilterCriteria
    let eventsManager: EventsDataManager
    
    @State private var searchText = ""
    @State private var selectedCities: [String] = []
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var showingDatePicker = false
    @State private var selectedSports: Set<String> = []
    
    // Получаем списки из EventsDataManager
    var availableCities: [String] {
        eventsManager.availableCities
    }
    
    var availableSports: [String] {
        eventsManager.availableSports
    }
    
    init(filterCriteria: Binding<FilterCriteria>, eventsManager: EventsDataManager) {
        self._filterCriteria = filterCriteria
        self.eventsManager = eventsManager
        self._selectedCities = State(initialValue: filterCriteria.wrappedValue.selectedCities)
        self._startDate = State(initialValue: filterCriteria.wrappedValue.startDate ?? Date())
        self._endDate = State(initialValue: filterCriteria.wrappedValue.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        self._selectedSports = State(initialValue: filterCriteria.wrappedValue.selectedSports)
    }
    
    var filteredCities: [String] {
        if searchText.isEmpty {
            return availableCities
        } else {
            return availableCities.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // City Search Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("City")
                                .foregroundColor(.white)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Кнопка сброса городов
                            if !selectedCities.isEmpty {
                                Button("Очистить") {
                                    selectedCities.removeAll()
                                }
                                .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                                .font(.caption)
                            }
                        }
                        
                        // Search Field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search city", text: $searchText)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        
                        // Selected Cities
                        if !selectedCities.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                                ForEach(selectedCities, id: \.self) { city in
                                    CityTag(city: city, isSelected: true) {
                                        selectedCities.removeAll { $0 == city }
                                    }
                                }
                            }
                        }
                        
                        // Available Cities
                        if !searchText.isEmpty {
                            ScrollView {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                                    ForEach(filteredCities.filter { !selectedCities.contains($0) }, id: \.self) { city in
                                        CityTag(city: city, isSelected: false) {
                                            if !selectedCities.contains(city) {
                                                selectedCities.append(city)
                                                searchText = ""
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                        }
                    }
                    
                    // Date Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Date")
                                .foregroundColor(.white)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Кнопка сброса дат - показываем если даты изменены от значений по умолчанию
                            if isDateFilterActive {
                                Button("Сбросить") {
                                    resetDateFilter()
                                }
                                .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                                .font(.caption)
                            }
                        }
                        
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            HStack {
                                Text(dateDisplayText)
                                    .foregroundColor(isDateFilterActive ? .white : .gray)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Sport Types Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Sport Types")
                                .foregroundColor(.white)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Кнопка сброса видов спорта
                            if !selectedSports.isEmpty {
                                Button("Очистить") {
                                    selectedSports.removeAll()
                                }
                                .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                                .font(.caption)
                            }
                        }
                        
                        if !availableSports.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                                ForEach(availableSports, id: \.self) { sport in
                                    SportTag(
                                        sport: sport,
                                        isSelected: selectedSports.contains(sport)
                                    ) {
                                        if selectedSports.contains(sport) {
                                            selectedSports.remove(sport)
                                        } else {
                                            selectedSports.insert(sport)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("Нет доступных видов спорта")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    // Кнопка сброса всех фильтров
                    if hasActiveFilters {
                        Button(action: {
                            resetAllFilters()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Сбросить все фильтры")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.6))
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Date Picker Overlay
                if showingDatePicker {
                    DatePickerOverlay(
                        startDate: $startDate,
                        endDate: $endDate,
                        isShowing: $showingDatePicker
                    )
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Применяем фильтры
                        filterCriteria.selectedCities = selectedCities
                        filterCriteria.selectedSports = selectedSports
                        
                        // Применяем фильтр дат если он активен
                        if isDateFilterActive {
                            filterCriteria.startDate = startDate
                            filterCriteria.endDate = endDate
                        } else {
                            filterCriteria.startDate = nil
                            filterCriteria.endDate = nil
                        }
                        
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Private Methods
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    // Отображаемый текст для поля дат
    private var dateDisplayText: String {
        if isDateFilterActive {
            return dateRangeString
        } else {
            return "Выберите период дат"
        }
    }
    
    // Проверяет, активен ли фильтр дат (отличается от значений по умолчанию)
    private var isDateFilterActive: Bool {
        let defaultStartDate = Date()
        let defaultEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        return !Calendar.current.isDate(startDate, inSameDayAs: defaultStartDate) ||
               !Calendar.current.isDate(endDate, inSameDayAs: defaultEndDate)
    }
    
    private var hasActiveFilters: Bool {
        return !selectedCities.isEmpty ||
               !selectedSports.isEmpty ||
               isDateFilterActive
    }
    
    private func resetAllFilters() {
        selectedCities.removeAll()
        selectedSports.removeAll()
        resetDateFilter()
    }
    
    private func resetDateFilter() {
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }
}

// MARK: - Supporting Views

struct CityTag: View {
    let city: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(city)
                    .foregroundColor(isSelected ? .black : .white)
                    .font(.system(size: 14))
                    .lineLimit(1)
                
                if isSelected {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .font(.system(size: 10))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(red: 0.0, green: 0.8, blue: 0.7) : Color.gray.opacity(0.3))
            .cornerRadius(20)
        }
    }
}

struct SportTag: View {
    let sport: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(sport)
                    .foregroundColor(isSelected ? .black : .gray)
                    .font(.system(size: 16))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color(red: 0.0, green: 0.8, blue: 0.7) : Color.gray.opacity(0.2))
            .cornerRadius(25)
        }
    }
}

struct DatePickerOverlay: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }
            
            VStack(spacing: 20) {
                HStack {
                    Text("Select Date Range")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Кнопка сброса дат в оверлее
                    Button("Сбросить") {
                        let defaultStartDate = Date()
                        let defaultEndDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                        startDate = defaultStartDate
                        endDate = defaultEndDate
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                    .font(.caption)
                }
                
                VStack(spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("Start Date")
                            .foregroundColor(.gray)
                            .font(.caption)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .colorScheme(.dark)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("End Date")
                            .foregroundColor(.gray)
                            .font(.caption)
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .colorScheme(.dark)
                    }
                }
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isShowing = false
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    
                    Button("Done") {
                        isShowing = false
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.0, green: 0.8, blue: 0.7).opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding(20)
            .background(Color.gray.opacity(0.1))
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
}
