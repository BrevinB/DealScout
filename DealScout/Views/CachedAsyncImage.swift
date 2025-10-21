//
//  CachedAsyncImage.swift
//  DealScout
//
//  Cached Async Image View with Offline Support
//

import SwiftUI

// MARK: - Cached Async Image

/// AsyncImage replacement with built-in caching support
struct CachedAsyncImage<Content: View, Placeholder: View>: View {

    // MARK: - Properties

    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var imageData: Data?
    @State private var isLoading = false

    private let cacheManager = CacheManager.shared

    // MARK: - Initialization

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task {
            await loadImage()
        }
    }

    // MARK: - Private Methods

    private func loadImage() async {
        guard let url = url else { return }

        isLoading = true

        // Try to get cached image first
        if let cachedData = await cacheManager.getCachedImage(from: url) {
            imageData = cachedData
            isLoading = false
            return
        }

        // Download and cache the image
        if let downloadedData = await cacheManager.cacheImage(from: url) {
            imageData = downloadedData
        }

        isLoading = false
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    /// Convenience initializer with default placeholder
    init(url: URL?) {
        self.init(
            url: url,
            content: { image in image },
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}

extension CachedAsyncImage where Placeholder == Color {
    /// Convenience initializer with content closure and default placeholder
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}

extension CachedAsyncImage where Content == Image {
    /// Convenience initializer with placeholder closure
    init(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: url,
            content: { image in image },
            placeholder: placeholder
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CachedAsyncImage(url: URL(string: "https://picsum.photos/200/200"))
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        CachedAsyncImage(
            url: URL(string: "https://picsum.photos/200/200")
        ) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}