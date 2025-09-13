import SwiftUI
import UIKit

// MARK: - Typography System
/// Централизованная система управления шрифтами в приложении
/// Использует системные шрифты Helvetica Neue и Avenir Next
struct Typography {
    
    // MARK: - Font Names (системные шрифты с полной поддержкой кириллицы)
    private enum FontName {
        // ✅ SF Pro - основной системный шрифт iOS с отличной поддержкой кириллицы
        static let sfProRegular = ".SFUI-Regular"
        static let sfProMedium = ".SFUI-Medium" 
        static let sfProSemiBold = ".SFUI-Semibold"
        static let sfProBold = ".SFUI-Bold"
        
        // ✅ Avenir Next - отличная альтернатива, похожая на Trade Gothic
        static let avenirNext = "AvenirNext-Regular"
        static let avenirNextMedium = "AvenirNext-Medium"
        static let avenirNextDemiBold = "AvenirNext-DemiBold"
        static let avenirNextBold = "AvenirNext-Bold"
        
        // ✅ Для плотных заголовков (похоже на Trade Gothic)
        static let avenirNextCondensed = "AvenirNextCondensed-Regular"
        static let avenirNextCondensedMedium = "AvenirNextCondensed-Medium"
        static let avenirNextCondensedDemiBold = "AvenirNextCondensed-DemiBold"
        static let avenirNextCondensedBold = "AvenirNextCondensed-Bold"
    }
    
    // MARK: - Font Weights & Styles (смешанная система)
    static let largeTitle = createFontSpecific(size: 34, fontName: "Arial-BoldMT", fallbackWeight: .bold)
    static let title1 = createFontSpecific(size: 28, fontName: "Arial-BoldMT", fallbackWeight: .bold)
    static let title2 = createFontSpecific(size: 22, fontName: "Arial-BoldMT", fallbackWeight: .semibold)
    static let title3 = createFontSpecific(size: 20, fontName: "Arial", fallbackWeight: .medium)
    
    // Helvetica Neue Condensed Bold для заголовков событий (компактный стиль)
    static let eventTitle = createFontSpecific(size: 17, fontName: "HelveticaNeue-CondensedBold", fallbackWeight: .semibold)
    static let eventDetailTitle = createFontSpecific(size: 24, fontName: "HelveticaNeue-CondensedBold", fallbackWeight: .semibold)
    static let headline = createFontSpecific(size: 17, fontName: "HelveticaNeue-CondensedBold", fallbackWeight: .bold)
    
    // Helvetica для адреса и даты (как вы просили)
    static let subheadline = createFontSpecific(size: 15, fontName: "HelveticaNeue", fallbackWeight: .regular)
    static let eventDetailSubheadline = createFontSpecific(size: 14, fontName: "HelveticaNeue", fallbackWeight: .regular)
    static let eventDetailBody = createFontSpecific(size: 15, fontName: "HelveticaNeue", fallbackWeight: .regular)
    
    // Секции для страницы события - менее жирные
    static let eventDetailSectionTitle = createFontSpecific(size: 18, fontName: "HelveticaNeue-Medium", fallbackWeight: .medium)
    
    static let body = createFontSpecific(size: 17, fontName: "Arial", fallbackWeight: .regular)
    static let bodyMedium = createFontSpecific(size: 17, fontName: "Arial", fallbackWeight: .medium)
    
    static let callout = createFontSpecific(size: 16, fontName: "Arial", fallbackWeight: .regular)
    static let footnote = createFontSpecific(size: 13, fontName: "HelveticaNeue", fallbackWeight: .regular)
    static let caption1 = createFontSpecific(size: 12, fontName: "HelveticaNeue", fallbackWeight: .regular)
    static let caption2 = createFontSpecific(size: 11, fontName: "HelveticaNeue", fallbackWeight: .regular)
    
    // MARK: - Custom Sizes
    static func customSize(_ size: CGFloat, weight: FontWeight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold, .heavy:
            fontName = FontName.avenirNextBold
        case .semibold:
            fontName = FontName.avenirNextDemiBold
        case .medium:
            fontName = FontName.avenirNextMedium
        case .light, .ultraLight, .thin:
            fontName = FontName.avenirNext
        default:
            fontName = FontName.avenirNext
        }
        
        return createFont(size: size, primary: fontName, weight: weight.swiftUIWeight)
    }
    
    // MARK: - Font Creation with Fallback
    private static func createFont(size: CGFloat, primary: String, weight: Font.Weight) -> Font {
        // Принудительно используем Arial для консистентности между языками
        if UIFont(name: "Arial", size: size) != nil {
            return Font.custom("Arial", size: size).weight(weight)
        } else {
            return Font.system(size: size, weight: weight, design: .default)
        }
    }
    
    // MARK: - Specific Font Creation
    private static func createFontSpecific(size: CGFloat, fontName: String, fallbackWeight: Font.Weight) -> Font {
        // Проверяем доступность конкретного шрифта
        if UIFont(name: fontName, size: size) != nil {
            print("✅ Используем шрифт: \(fontName)")
            return Font.custom(fontName, size: size)
        } else {
            print("⚠️ Шрифт \(fontName) недоступен, используем системный")
            return Font.system(size: size, weight: fallbackWeight, design: .default)
        }
    }
    
    // MARK: - Font Weight Enum
    enum FontWeight {
        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        
        var swiftUIWeight: Font.Weight {
            switch self {
            case .ultraLight: return .ultraLight
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            }
        }
    }
    
    // MARK: - Font Debugging
    /// Печатает все доступные шрифты для отладки
    static func printAvailableFonts() {
        print("🔤 Доступные семейства шрифтов:")
        for family in UIFont.familyNames.sorted() {
            print("📁 \(family)")
            for font in UIFont.fontNames(forFamilyName: family) {
                print("   - \(font)")
            }
        }
    }
    
    /// Проверяет доступность системных шрифтов
    static func validateCustomFonts() {
        let fonts = [
            FontName.avenirNext,
            FontName.avenirNextMedium,
            FontName.avenirNextDemiBold,
            FontName.avenirNextBold,
            FontName.avenirNextCondensed,
            FontName.avenirNextCondensedMedium,
            FontName.avenirNextCondensedDemiBold,
            FontName.avenirNextCondensedBold,
            FontName.sfProRegular
        ]
        
        print("🔍 Проверка системных шрифтов:")
        for fontName in fonts {
            if UIFont(name: fontName, size: 16) != nil {
                print("✅ \(fontName) - доступен")
            } else {
                print("❌ \(fontName) - недоступен")
            }
        }
    }
}

// MARK: - Font Extension for Easy Usage
extension Font {
    // Быстрый доступ к типографике приложения
    static var appLargeTitle: Font { Typography.largeTitle }
    static var appTitle1: Font { Typography.title1 }
    static var appTitle2: Font { Typography.title2 }
    static var appTitle3: Font { Typography.title3 }
    static var appEventTitle: Font { Typography.eventTitle }  // Специально для заголовков событий
    static var appEventDetailTitle: Font { Typography.eventDetailTitle }  // Для заголовка на странице события
    static var appHeadline: Font { Typography.headline }
    static var appSubheadline: Font { Typography.subheadline }
    static var appEventDetailSubheadline: Font { Typography.eventDetailSubheadline }  // Для подзаголовков на странице события
    static var appEventDetailBody: Font { Typography.eventDetailBody }  // Для основного текста на странице события
    static var appEventDetailSectionTitle: Font { Typography.eventDetailSectionTitle }  // Для заголовков секций на странице события
    static var appBody: Font { Typography.body }
    static var appBodyMedium: Font { Typography.bodyMedium }
    static var appCallout: Font { Typography.callout }
    static var appFootnote: Font { Typography.footnote }
    static var appCaption1: Font { Typography.caption1 }
    static var appCaption2: Font { Typography.caption2 }
    
    /// Кастомный размер с типографикой приложения
    static func appCustom(_ size: CGFloat, weight: Typography.FontWeight = .regular) -> Font {
        Typography.customSize(size, weight: weight)
    }
}

// MARK: - Preview для тестирования шрифтов
struct TypographyPreview: View {
    
    @State private var showFontList = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Основные стили
                    Group {
                        Text("Large Title - Avenir Next Condensed Bold")
                            .font(.appLargeTitle)
                        
                        Text("Title 1 - Avenir Next Condensed DemiBold")
                            .font(.appTitle1)
                        
                        Text("Title 2 - Avenir Next Condensed Medium")
                            .font(.appTitle2)
                        
                        Text("Title 3 - Avenir Next Medium")
                            .font(.appTitle3)
                        
                        Text("Headline - Avenir Next DemiBold")
                            .font(.appHeadline)
                    }
                    
                    Divider()
                    
                    // Текстовые стили
                    Group {
                        Text("Subheadline - Avenir Next Regular")
                            .font(.appSubheadline)
                        
                        Text("Body - Основной текст для чтения. Avenir Next обеспечивает отличную читаемость как для English так и для Русского")
                            .font(.appBody)
                        
                        Text("Body Medium - Выделенный текст. Avenir Next Medium")
                            .font(.appBodyMedium)
                        
                        Text("Callout - Avenir Next Regular")
                            .font(.appCallout)
                    }
                    
                    Divider()
                    
                    // Мелкие стили
                    Group {
                        Text("Footnote - SF Pro Regular")
                            .font(.appFootnote)
                        
                        Text("Caption 1 - SF Pro Regular")
                            .font(.appCaption1)
                        
                        Text("Caption 2 - SF Pro Regular")
                            .font(.appCaption2)
                    }
                    
                    Divider()
                    
                    // Кастомные размеры
                    Group {
                        Text("Custom 24pt Bold - Avenir Next Bold")
                            .font(.appCustom(24, weight: .bold))
                        
                        Text("Custom 18pt Medium - Avenir Next Medium")
                            .font(.appCustom(18, weight: .medium))
                        
                        Text("Custom 14pt Light - Avenir Next Regular")
                            .font(.appCustom(14, weight: .light))
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .background(Color.black)
            .foregroundColor(.white)
            .navigationTitle("Типографика")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        Typography.printAvailableFonts()
                        Typography.validateCustomFonts()
                    }
                }
            }
        }
    }
}

#Preview {
    TypographyPreview()
}