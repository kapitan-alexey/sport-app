import SwiftUI

// MARK: - Enhanced Error View
struct ErrorView: View {
    let message: String
    let cacheStatus: CacheStatus
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.appCustom(50))
                .foregroundColor(.red)
            
            Text("Ошибка загрузки")
                .font(.appTitle2)
                .foregroundColor(.white)
            
            Text(message)
                .font(.appBody)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Информация о кеше
            if cacheStatus.hasCache {
                VStack(spacing: 8) {
                    Text("💾 В кеше: \(cacheStatus.eventCount) событий")
                        .font(.appCaption1)
                        .foregroundColor(.blue)
                    
                    Text("Размер: \(cacheStatus.size)")
                        .font(.appCaption1)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Повторить")
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 0.0, green: 0.8, blue: 0.7))
                .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}