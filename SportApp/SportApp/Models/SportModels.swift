import Foundation

// MARK: - Sport Model
struct Sport: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let iconName: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case iconName = "icon_name"
    }
}

// MARK: - City Model
struct City: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

// MARK: - SportEvent Model
struct SportEvent: Codable, Identifiable {
    let id: Int
    let name: String
    let date: Date  // ✅ Это поле используется для фильтрации по дате
    let photoMain: String?
    let iconNames: String?
    let fullDescription: String?
    let shortDescription: String?
    let organizer: String?
    let websiteUrl: String?
    let availableDistances: String?
    let eventFormat: String?
    let ageCategories: String?
    let address: String?
    let latitude: Double
    let longitude: Double
    let contactPhone: String?
    let contactEmail: String?
    let registrationUrl: String?
    let registrationDeadline: Date?
    let maxParticipants: Int
    let currentParticipants: Int
    let price: String?
    let photoGallery: String?
    let videoUrl: String?
    let cityId: Int
    let city: City
    let sports: [Sport]
    let cityName: String
    let sportName: String
    let isUpcoming: Bool
    let canRegister: Bool
    let occupancyPercentage: Double
    let availableSpots: Int
    let availableDistancesArray: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, date, organizer, address, latitude, longitude, price, city, sports
        case photoMain = "photo_main"
        case iconNames = "icon_names"
        case fullDescription = "full_description"
        case shortDescription = "short_description"
        case websiteUrl = "website_url"
        case availableDistances = "available_distances"
        case eventFormat = "event_format"
        case ageCategories = "age_categories"
        case contactPhone = "contact_phone"
        case contactEmail = "contact_email"
        case registrationUrl = "registration_url"
        case registrationDeadline = "registration_deadline"
        case maxParticipants = "max_participants"
        case currentParticipants = "current_participants"
        case photoGallery = "photo_gallery"
        case videoUrl = "video_url"
        case cityId = "city_id"
        case cityName = "city_name"
        case sportName = "sport_name"
        case isUpcoming = "is_upcoming"
        case canRegister = "can_register"
        case occupancyPercentage = "occupancy_percentage"
        case availableSpots = "available_spots"
        case availableDistancesArray = "available_distances_array"
    }
}

// MARK: - SportEvent Extensions
extension SportEvent {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, yyyy"
        return formatter.string(from: date)
    }
    
    var photoGalleryArray: [String] {
        guard let galleryString = photoGallery, !galleryString.isEmpty else { return [] }
        return galleryString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
    
    var sportTagsArray: [String] {
        return sports.map { $0.iconName }
    }
    
    // ✅ ОБРАБОТКА URL ИЗОБРАЖЕНИЙ
    var fullPhotoMainURL: String? {
        guard let photoMain = photoMain, !photoMain.isEmpty else { return nil }
        
        // Если уже полный URL - возвращаем как есть
        if photoMain.hasPrefix("http") {
            print("🔗 Полный URL: \(photoMain)")
            return photoMain
        }
        
        // Если частичный путь - дособираем полный URL
        let baseURL = "http://192.168.0.136:9000/uploads"
        
        // Убираем лишние слэши и форматируем
        let cleanPath = photoMain.hasPrefix("/") ? String(photoMain.dropFirst()) : photoMain
        let fullURL = "\(baseURL)/\(cleanPath)"
        
        print("🔄 Конвертируем URL: '\(photoMain)' -> '\(fullURL)'")
        return fullURL
    }
}

// MARK: - Удален старый EventsDataManager - теперь используется новый из EventsDataManager.swift
