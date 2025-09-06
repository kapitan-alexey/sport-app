import SwiftUI
import MapKit
import SafariServices

// MARK: - Custom MapView для корректного отображения
struct MapView: UIViewRepresentable {
    let latitude: Double
    let longitude: Double
    let eventName: String
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = false
        mapView.mapType = .standard
        
        // Создаем аннотацию
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.title = eventName
        mapView.addAnnotation(annotation)
        
        // Устанавливаем регион с нужным зумом
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        mapView.setRegion(region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Обновления не требуются
    }
}

// MARK: - SafariView Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.dismissButtonStyle = .close
        safariViewController.preferredBarTintColor = UIColor.black
        safariViewController.preferredControlTintColor = UIColor(red: 18/255, green: 250/255, blue: 210/255, alpha: 1.0)
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Не требуется обновление
    }
}

// MARK: - Files View
struct EventFilesView: View {
    let files: [EventFile]
    @Environment(\.dismiss) private var dismiss
    @State private var showingSafari = false
    @State private var selectedFileURL: URL?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if files.isEmpty {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Файлы отсутствуют")
                            .font(.appTitle2)
                            .foregroundColor(.gray)
                            .padding(.top, 16)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(files) { file in
                                Button(action: {
                                    openFile(file)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.fill")
                                            .font(.title2)
                                            .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                                        
                                        Text(file.name)
                                            .font(.appBody)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .foregroundColor(Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Файлы")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button("Готово") {
                    dismiss()
                }
                .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
            )
        }
        .sheet(isPresented: $showingSafari) {
            if let url = selectedFileURL {
                SafariView(url: url)
            }
        }
    }
    
    private func openFile(_ file: EventFile) {
        guard let url = URL(string: file.fileUrl) else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        selectedFileURL = url
        showingSafari = true
    }
}

// MARK: - Event Detail View
struct EventDetailView: View {
    let event: SportEvent
    @Environment(\.dismiss) private var dismiss
    @State private var showingSafari = false
    @State private var showingWebsiteSafari = false
    @State private var showingRegistrationAlert = false
    @State private var registrationAlertMessage = ""
    @State private var showingFullDescription = false
    @State private var showingFiles = false
    @ObservedObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        ZStack {
            // Основной контент
            ScrollView {
                LazyVStack(spacing: 0) {
                    // ✅ Header Image БЕЗ ignoresSafeArea
                    CachedAsyncImage(
                        url: URL(string: event.fullPhotoMainURL ?? "")
                    ) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.purple.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        )
                    } failure: {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(0.4),
                                Color.orange.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Не удалось загрузить")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                    }
                    .frame(height: 300)
                    .clipped()

                    // Title and Basic Info
                    titleSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    // Description
                    descriptionSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    // Distances
                    distancesSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // Files Section
                    filesSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // Location
                    locationSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // Contacts
                    contactsSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // Registration Button
                    registrationButton
                        .padding(.horizontal, 16)
                        .padding(.top, 32)
                    
                    Spacer().frame(height: 100)
                }
            }
            .ignoresSafeArea(edges: .top) // ✅ Только ScrollView игнорирует Safe Area
            
            // ✅ КНОПКА НАЗАД через safeAreaInset с правильным вертикальным позиционированием
            VStack {
                Spacer()
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 8) // ✅ Отступ сверху от Safe Area
                    
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                    }
                    
                    Spacer().frame(height: 8) // ✅ Отступ снизу
                }
                .background(Color.clear)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSafari) {
            if let registrationUrl = event.registrationUrl,
               let url = URL(string: registrationUrl) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showingWebsiteSafari) {
            if let websiteUrl = event.websiteUrl,
               let url = URL(string: websiteUrl) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showingFiles) {
            EventFilesView(files: event.files)
        }
        .alert("Уведомление", isPresented: $showingRegistrationAlert) {
            Button("OK") { }
        } message: {
            Text(registrationAlertMessage)
        }
    }

    // Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(event.name)
                    .font(.appEventDetailTitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        favoritesManager.toggleFavorite(eventID: event.id)
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: favoritesManager.isFavorite(eventID: event.id) ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(favoritesManager.isFavorite(eventID: event.id) ? Color(red: 18/255, green: 250/255, blue: 210/255) : .white)
                }
            }

            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                Text("\(event.cityName) • \(event.shortFormattedDate)")
                    .font(.appEventDetailSubheadline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                HStack(spacing: 4) {
                    ForEach(event.sports.prefix(3), id: \.id) { sport in
                        Image(customIconName(for: sport.name))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Исправленная Description Section (без кнопки сайта)
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Отображаем короткое или полное описание в зависимости от состояния
            Text(descriptionText)
                .font(.custom("HelveticaNeue", size: 15))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(showingFullDescription ? nil : 3)
                .animation(.easeInOut(duration: 0.3), value: showingFullDescription)
            
            // Кнопка "Подробнее" / "Свернуть" для переключения описания
            if shouldShowToggleButton {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFullDescription.toggle()
                    }
                }) {
                    Text(showingFullDescription ? "Свернуть" : "Подробнее")
                        .font(.appEventDetailBody)
                        .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Distances Section
    private var distancesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Дистанции")
                .font(.appEventDetailSectionTitle)
                .foregroundColor(.white)
            
            if !event.availableDistancesArray.isEmpty {
                // Горизонтальный скролл с компактными элементами
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(event.availableDistancesArray, id: \.self) { distance in
                            Text(distance)
                                .font(.custom("HelveticaNeue-Medium", size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255).opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(red: 18/255, green: 250/255, blue: 210/255).opacity(0.4), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16) // Компенсируем внешний отступ
            } else {
                Text("Дистанции уточняются")
                    .font(.appEventDetailBody)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Files Section
    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Файлы")
                .font(.appEventDetailSectionTitle)
                .foregroundColor(.white)
            
            if !event.files.isEmpty {
                Button(action: {
                    showingFiles = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Документы")
                                .font(.appHeadline)
                                .foregroundColor(.white)
                            Text("\(event.files.count) файл(ов)")
                                .font(.appCaption1)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundColor(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text("Файлы отсутствуют")
                    .font(.appEventDetailBody)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ✅ ОБНОВЛЕННАЯ Location Section с улучшенной картой
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Место проведения")
                .font(.appEventDetailSectionTitle)
                .foregroundColor(.white)
            
            if let address = event.address, !address.isEmpty {
                Text(address)
                    .font(.appEventDetailBody)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if event.latitude != 0.0 && event.longitude != 0.0 {
                // ✅ Исправленная карта для iOS 16+
                MapView(
                    latitude: event.latitude,
                    longitude: event.longitude,
                    eventName: event.name
                )
                .frame(height: 200)
                .cornerRadius(12)
                
                Button(action: {
                    openInMaps()
                }) {
                    Text("Показать на карте")
                        .font(.appEventDetailBody)
                        .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Обновленная Contacts Section с кликабельными элементами
    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Контакты")
                .font(.appEventDetailSectionTitle)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                if let organizer = event.organizer, !organizer.isEmpty {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                        Text("Организатор: \(organizer)")
                            .font(.appEventDetailBody)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                if let email = event.contactEmail, !email.isEmpty {
                    Button(action: {
                        sendEmail(email)
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                            Text(email)
                                .font(.appEventDetailBody)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                if let phone = event.contactPhone, !phone.isEmpty {
                    Button(action: {
                        callPhone(phone)
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                            Text(phone)
                                .font(.appEventDetailBody)
                                .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                        }
                    }
                }

                
                // Кнопка сайта
                if let websiteUrl = event.websiteUrl, !websiteUrl.isEmpty {
                    Button(action: {
                        openWebsite()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                            Text(cleanURL(websiteUrl))
                                .font(.appEventDetailBody)
                                .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ✅ НОВАЯ Registration Button с встроенным Safari
    private var registrationButton: some View {
        VStack(spacing: 12) {
//            if let price = event.price, !price.isEmpty {
//                Text("Цена: \(price)")
//                    .font(.appHeadline)
//                    .foregroundColor(.white)
//            }
            
            Button(action: {
                handleRegistrationWithSafari()
            }) {
                HStack {
                    if event.canRegister {
                        Image(systemName: "link")
                            .font(.title3)
                    }
                    Text(event.canRegister ? "Зарегистрироваться" : "Регистрация закрыта")
                        .font(.appHeadline)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    event.canRegister
                        ? Color(red: 18/255, green: 250/255, blue: 210/255)
                        : Color.gray
                )
                .cornerRadius(12)
                .scaleEffect(event.canRegister ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.1), value: event.canRegister)
            }
            .disabled(!event.canRegister)
        }
    }
    
    // MARK: - Вспомогательные computed properties для описания
    private var descriptionText: String {
        if showingFullDescription {
            return event.fullDescription ?? defaultDescription
        } else {
            return event.shortDescription ?? defaultDescription
        }
    }

    private var shouldShowToggleButton: Bool {
        // Показываем кнопку переключения только если есть и короткое и полное описание
        // и они отличаются друг от друга
        guard let short = event.shortDescription,
              let full = event.fullDescription,
              !short.isEmpty,
              !full.isEmpty,
              short != full else {
            return false
        }
        return true
    }

    private var defaultDescription: String {
        "Главный забег с препятствиями и велозаезд в Казахстана. Дистанции для взрослых 3, 5 и 10 км, для детей 1 и 2 км. Участие личное и командное."
    }
    
    // ✅ УЛУЧШЕННЫЕ функции для обработки контактов
    private func callPhone(_ phone: String) {
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+", with: "")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if let url = URL(string: "tel:\(cleanPhone)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback - копируем номер в буфер обмена
                UIPasteboard.general.string = phone
                registrationAlertMessage = "Номер телефона скопирован: \(phone)"
                showingRegistrationAlert = true
            }
        }
    }
    
    private func sendEmail(_ email: String) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback - копируем email в буфер обмена
                UIPasteboard.general.string = email
                registrationAlertMessage = "Email скопирован: \(email)"
                showingRegistrationAlert = true
            }
        }
    }
    
    private func openWebsite() {
        guard let websiteUrl = event.websiteUrl,
              !websiteUrl.isEmpty else {
            return
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Проверяем валидность URL
        guard URL(string: websiteUrl) != nil else {
            registrationAlertMessage = "Некорректная ссылка на сайт"
            showingRegistrationAlert = true
            return
        }
        
        // Открываем сайт через встроенный Safari
        showingWebsiteSafari = true
    }

    
    // ✅ НОВАЯ функция обработки регистрации
    private func handleRegistrationWithSafari() {
        // Haptic feedback для лучшего UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        guard event.canRegister else {
            registrationAlertMessage = "Регистрация на это событие уже закрыта"
            showingRegistrationAlert = true
            return
        }
        
        guard let registrationUrl = event.registrationUrl,
              !registrationUrl.isEmpty,
              URL(string: registrationUrl) != nil else {
            registrationAlertMessage = "Ссылка на регистрацию недоступна. Обратитесь к организаторам."
            showingRegistrationAlert = true
            return
        }
        
        // Открываем Safari внутри приложения
        showingSafari = true
    }
    
    // ✅ НОВАЯ функция для открытия в Apple Maps
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = event.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        ])
    }
    
    private func cleanURL(_ url: String) -> String {
        var cleanedURL = url
        if cleanedURL.hasPrefix("https://") {
            cleanedURL = String(cleanedURL.dropFirst(8))
        } else if cleanedURL.hasPrefix("http://") {
            cleanedURL = String(cleanedURL.dropFirst(7))
        }
        return cleanedURL
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
