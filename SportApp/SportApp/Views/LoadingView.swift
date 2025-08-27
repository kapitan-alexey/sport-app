import SwiftUI

// MARK: - Enhanced Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.0, green: 0.8, blue: 0.7)))
                .scaleEffect(1.5)
            
            Text("Загрузка событий...")
                .font(.appHeadline)
                .foregroundColor(.white)
            
            Text("Подключение к серверу...")
                .font(.appCaption1)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}