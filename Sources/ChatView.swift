import SwiftUI
import PhotosUI
import UIKit

struct PendingImage: Identifiable {
    var id = UUID()
    var image: UIImage
    var attachment: ImageAttachment
}

struct ChatView: View {
    @EnvironmentObject private var store: OdysseusStore

    private let client = OpenAIClient()
    private let apiKeyName = "openai_api_key"

    @State private var inputText = ""
    @State private var isSending = false
    @State private var errorText: String?
    @State private var showingConversations = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var pendingImages: [PendingImage] = []
    @State private var showingExport = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.currentMessages.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                if let errorText {
                    Text(errorText)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                }

                composer
            }
            .navigationTitle(store.currentConversation?.title ?? "Odysseus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingConversations = true
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        store.newConversation()
                    } label: {
                        Image(systemName: "plus")
                    }

                    Menu {
                        Button("Clear current chat", role: .destructive) {
                            store.clearCurrentConversation()
                        }

                        Button("Export current chat") {
                            showingExport = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingConversations) {
                ConversationListView()
            }
            .sheet(isPresented: $showingExport) {
                ExportView(text: store.exportCurrentConversation())
            }
            .onChange(of: selectedPhotoItems) { newItems in
                Task {
                    await loadSelectedPhotos(newItems)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bolt.horizontal.circle")
                .font(.system(size: 58))
                .foregroundColor(.accentColor)

            Text("Odysseus Mobile")
                .font(.title)
                .bold()

            Text("Standalone. No PC backend. Add your API key in Settings, then send a message.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("New Chat") {
                store.newConversation()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.currentMessages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if isSending {
                        HStack {
                            ProgressView()
                            Text("Odysseus is thinking...")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .onChange(of: store.currentMessages.count) { _ in
                if let last = store.currentMessages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if !pendingImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(pendingImages) { pending in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: pending.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipped()
                                    .cornerRadius(12)

                                Button {
                                    pendingImages.removeAll { $0.id == pending.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(alignment: .bottom, spacing: 10) {
                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 4, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                }
                .disabled(isSending)

                TextField("Message Odysseus...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .disabled(isSending)

                Button {
                    Task {
                        await send()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(isSending || (inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pendingImages.isEmpty))
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    private func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = pendingImages.map { $0.attachment }

        guard !text.isEmpty || !attachments.isEmpty else { return }

        errorText = nil
        inputText = ""
        pendingImages.removeAll()
        selectedPhotoItems.removeAll()

        store.addUserMessage(text: text, images: attachments)

        isSending = true
        defer { isSending = false }

        do {
            let apiKey = KeychainStore.load(apiKeyName)
            let response = try await client.send(
                messages: store.currentMessages,
                apiKey: apiKey,
                settings: store.settings,
                developerPrompt: store.developerPrompt()
            )
            store.addAssistantMessage(response)
        } catch {
            let message = error.localizedDescription
            errorText = message
            store.addErrorMessage(message)
        }
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        pendingImages.removeAll()

        for item in items.prefix(4) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data),
                      let jpegData = uiImage.jpegData(compressionQuality: 0.72) else {
                    continue
                }

                let base64 = jpegData.base64EncodedString()
                let attachment = ImageAttachment(
                    name: "image.jpg",
                    mimeType: "image/jpeg",
                    base64Data: base64
                )

                pendingImages.append(PendingImage(image: uiImage, attachment: attachment))
            } catch {
                errorText = "Could not load selected photo: \(error.localizedDescription)"
            }
        }
    }
}
