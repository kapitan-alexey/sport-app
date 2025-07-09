import SwiftUI

// MARK: - Enhanced Cached Async Image
/// Улучшенный компонент для загрузки изображений с мгновенным отображением из кеша
struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let failure: () -> Failure
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var hasFailed = false
    
    private let imageService = ImageLoadingService.shared
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if hasFailed {
                failure()
            } else {
                placeholder()
            }
        }
        .onAppear {
            // ✅ Мгновенная проверка кеша при появлении
            checkCacheImmediately()
        }
    }
    
    /// Мгновенно проверяет кеш и запускает загрузку при необходимости
    private func checkCacheImmediately() {
        guard let url = url, image == nil else { return }
        
        // Синхронная проверка кеша для мгновенного отображения
        if let cachedImage = imageService.getCachedImage(for: url.absoluteString) {
            self.image = cachedImage
        } else {
            loadImage()
        }
    }
    
    /// Асинхронно загружает изображение из сети
    private func loadImage() {
        guard let url = url, !isLoading, image == nil else { return }
        
        isLoading = true
        hasFailed = false
        
        Task {
            let loadedImage = await imageService.loadImage(from: url.absoluteString)
            
            await MainActor.run {
                isLoading = false
                
                if let loadedImage = loadedImage {
                    self.image = loadedImage
                    self.hasFailed = false
                } else {
                    self.hasFailed = true
                }
            }
        }
    }
}
