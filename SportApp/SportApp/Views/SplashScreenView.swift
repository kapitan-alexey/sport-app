import SwiftUI

// MARK: - Splash Screen View
struct SplashScreenView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var isAnimationComplete = false
    
    let onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Черный фон
            Color.black
                .ignoresSafeArea(.all)
            
            // Логотип приложения
            Text("Dynamo")
                .font(.system(size: 48, weight: .medium, design: .default))
                .foregroundColor(Color(red: 18/255, green: 250/255, blue: 210/255))
                .opacity(logoOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Плавное появление логотипа
        withAnimation(.easeOut(duration: 1.2)) {
            logoOpacity = 1.0
        }
        
        // Завершение анимации через 2.0 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isAnimationComplete = true
            onAnimationComplete()
        }
    }
}

#Preview {
    SplashScreenView {
        print("Animation complete")
    }
}
