import SwiftUI

// MARK: - Enhanced Event Card View
struct EventCardView: View {
    let event: SportEvent
    @State private var showingDetail = false

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(spacing: 0) {
                // Изображение с улучшенным кешированием
                CachedAsyncImage(
                    url: URL(string: event.fullPhotoMainURL ?? "")
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.purple.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            Text("Загрузка...")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                } failure: {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.4),
                                Color.blue.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Изображение недоступно")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
                .frame(height: 140)
                .clipped()

                // Информация о событии
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.appEventTitle)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            Text(event.cityName)
                            Text("•")
                                .font(.appCustom(10))
                            Text(event.formattedDate)
                        }
                        .font(.appSubheadline)
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    SportIconsView(event: event)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            }
            .background(Color.black)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingDetail) {
            EventDetailView(event: event)
        }
    }
}

// MARK: - Sport Icons View
struct SportIconsView: View {
    let event: SportEvent

    var body: some View {
        HStack(spacing: 6) {
            ForEach(event.sports, id: \.id) { sport in
                SportIconView(sport: sport, size: 26)
            }
        }
    }
}

// MARK: - Sport Icon View
struct SportIconView: View {
    let sport: Sport
    let size: CGFloat

    var body: some View {
        Image(customIconName(for: sport.name))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
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