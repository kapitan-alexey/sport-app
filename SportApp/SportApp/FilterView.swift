import SwiftUI
import FirebaseAnalytics

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
    @State private var endDate: Date = {
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.month = 12
        components.day = 31
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var showingDatePicker = false
    @State private var selectedSports: Set<String> = []
    @State private var hasUserSelectedDates = false
    @State private var isCityDropdownOpen = false
    
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
        
        let defaultEndDate: Date = {
            var components = Calendar.current.dateComponents([.year], from: Date())
            components.month = 12
            components.day = 31
            return Calendar.current.date(from: components) ?? Date()
        }()
        self._endDate = State(initialValue: filterCriteria.wrappedValue.endDate ?? defaultEndDate)
        self._selectedSports = State(initialValue: filterCriteria.wrappedValue.selectedSports)
        self._hasUserSelectedDates = State(initialValue: filterCriteria.wrappedValue.startDate != nil || filterCriteria.wrappedValue.endDate != nil)
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
                    .onTapGesture {
                        // Закрыть dropdown и клавиатуру при клике на фон
                        if isCityDropdownOpen {
                            isCityDropdownOpen = false
                        }
                        // Скрыть клавиатуру
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                ScrollView {
                    VStack(spacing: 30) {
                    // City Search Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Города")
                                .foregroundColor(.white)
                                .font(.appEventTitle)
                            
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
                        
                        // Dropdown Field
                        CityDropdownField(
                            searchText: $searchText,
                            isDropdownOpen: $isCityDropdownOpen,
                            filteredCities: filteredCities.filter { !selectedCities.contains($0) },
                            onCitySelected: { city in
                                if !selectedCities.contains(city) {
                                    selectedCities.append(city)
                                    searchText = ""
                                }
                                // Скрыть клавиатуру после выбора города
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        )
                        
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
                        
                    }
                    
                    // Date Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Даты")
                                .foregroundColor(.white)
                                .font(.appEventTitle)
                            
                            Spacer()
                            
                            // Кнопка сброса дат - показываем если пользователь выбрал даты
                            if hasUserSelectedDates {
                                Button("Сбросить") {
                                    resetDateFilter()
                                }
                                .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                                .font(.caption)
                            }
                        }
                        
                        Button(action: {
                            // Скрыть клавиатуру перед открытием date picker
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            if !hasUserSelectedDates {
                                hasUserSelectedDates = true
                            }
                            showingDatePicker = true
                        }) {
                            HStack {
                                Text(hasUserSelectedDates ? dateRangeString : "Нажмите для выбора периода")
                                    .foregroundColor(.gray)
                                    .font(.appSubheadline)
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
                            Text("Виды спорта")
                                .foregroundColor(.white)
                                .font(.appEventTitle)
                            
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
                                .font(.appSubheadline)
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
                    
                    Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    // Скрыть клавиатуру при нажатии на любое место в ScrollView
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
                // Date Picker Overlay
                if showingDatePicker {
                    DatePickerOverlay(
                        startDate: $startDate,
                        endDate: $endDate,
                        isShowing: $showingDatePicker,
                        hasUserSelectedDates: $hasUserSelectedDates
                    )
                }
            }
            .navigationTitle("Фильтр")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отменить") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                    .font(.custom("HelveticaNeue", size: 17))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Применить") {
                        // Логируем применение фильтров
                        Analytics.logEvent("filters_applied", parameters: [
                            "cities_count": selectedCities.count,
                            "sports_count": selectedSports.count,
                            "has_date_filter": hasUserSelectedDates,
                            "cities": selectedCities.joined(separator: ","),
                            "sports": Array(selectedSports).joined(separator: ",")
                        ])
                        
                        print("📊 [Analytics] Filters applied: cities=\(selectedCities.count), sports=\(selectedSports.count), dates=\(hasUserSelectedDates)")
                        
                        // Применяем фильтры
                        filterCriteria.selectedCities = selectedCities
                        filterCriteria.selectedSports = selectedSports
                        
                        // Применяем фильтр дат если пользователь их выбирал
                        if hasUserSelectedDates {
                            filterCriteria.startDate = Calendar.current.startOfDay(for: startDate)
                            filterCriteria.endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                            print("🗓️ [Filter] Применены даты: \(filterCriteria.startDate!) - \(filterCriteria.endDate!)")
                        } else {
                            filterCriteria.startDate = nil
                            filterCriteria.endDate = nil
                            print("🗓️ [Filter] Даты сброшены")
                        }
                        
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                    .font(.custom("HelveticaNeue", size: 17))
                }
            })
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
            return "Нажмите для выбора периода"
        }
    }
    
    // Проверяет, активен ли фильтр дат (отличается от значений по умолчанию)
    private var isDateFilterActive: Bool {
        let defaultStartDate = Date()
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.month = 12
        components.day = 31
        let defaultEndDate = Calendar.current.date(from: components) ?? Date()
        
        return !Calendar.current.isDate(startDate, inSameDayAs: defaultStartDate) ||
               !Calendar.current.isDate(endDate, inSameDayAs: defaultEndDate)
    }
    
    private var hasActiveFilters: Bool {
        return !selectedCities.isEmpty ||
               !selectedSports.isEmpty ||
               hasUserSelectedDates
    }
    
    private func resetAllFilters() {
        selectedCities.removeAll()
        selectedSports.removeAll()
        resetDateFilter()
    }
    
    private func resetDateFilter() {
        startDate = Date()
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.month = 12
        components.day = 31
        endDate = Calendar.current.date(from: components) ?? Date()
        hasUserSelectedDates = false
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
                    .font(.appSubheadline)
                
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

struct CityDropdownField: View {
    @Binding var searchText: String
    @Binding var isDropdownOpen: Bool
    let filteredCities: [String]
    let onCitySelected: (String) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Text Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                ZStack(alignment: .leading) {
                    if searchText.isEmpty && !isDropdownOpen {
                        Text("Выберите город")
                            .foregroundColor(.gray)
                            .font(.appSubheadline)
                    }
                    TextField(isDropdownOpen ? "Поиск городов..." : "", text: $searchText)
                        .foregroundColor(isDropdownOpen ? .white : .gray)
                        .font(.appSubheadline)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .focused($isTextFieldFocused)
                        .onChange(of: searchText) { _ in
                            if !isDropdownOpen {
                                isDropdownOpen = true
                            }
                        }
                        .allowsHitTesting(isDropdownOpen)
                }
                
                // Dropdown Arrow
                Image(systemName: isDropdownOpen ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .contentShape(Rectangle())
            .onTapGesture {
                if isDropdownOpen {
                    // Если dropdown открыт, активируем TextField для ввода
                    isTextFieldFocused = true
                } else {
                    // Если dropdown закрыт, открываем его
                    isDropdownOpen = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            }
                
            // Dropdown List
            if isDropdownOpen && (!filteredCities.isEmpty || !searchText.isEmpty) {
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredCities, id: \.self) { city in
                                Button(action: {
                                    onCitySelected(city)
                                    isDropdownOpen = false
                                    isTextFieldFocused = false
                                }) {
                                    HStack {
                                        Text(city)
                                            .foregroundColor(.white)
                                            .font(.appSubheadline)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.clear)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if city != filteredCities.last {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .onChange(of: isTextFieldFocused) { focused in
            if !focused {
                isDropdownOpen = false
            }
        }
    }
}

struct DatePickerOverlay: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isShowing: Bool
    @Binding var hasUserSelectedDates: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Выберите период")
                        .foregroundColor(.white)
                        .font(.appEventTitle)
                    
                    Spacer()
                    
                    // Кнопка сброса дат в оверлее
                    Button("Сбросить") {
                        startDate = Date()
                        var components = Calendar.current.dateComponents([.year], from: Date())
                        components.month = 12
                        components.day = 31
                        endDate = Calendar.current.date(from: components) ?? Date()
                        hasUserSelectedDates = false
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                    .font(.caption)
                }
                
                VStack(spacing: 10) {
                    HStack {
                        Text("От:")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 50, alignment: .leading)
                        
                        Spacer()
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .colorScheme(.dark)
                            .onChange(of: startDate) { _ in
                                hasUserSelectedDates = true
                            }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    
                    HStack {
                        Text("До:")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 50, alignment: .leading)
                        
                        Spacer()
                        
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .colorScheme(.dark)
                            .onChange(of: endDate) { _ in
                                hasUserSelectedDates = true
                            }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                
                HStack(spacing: 15) {
                    Button("Отмена") {
                        isShowing = false
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                    
                    Button("ОК") {
                        isShowing = false
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.0, green: 0.8, blue: 0.7))
                    .cornerRadius(12)
                }
            }
            .padding(15)
            .background(Color.gray.opacity(0.1))
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .padding(.vertical, 50)
        }
    }
}
