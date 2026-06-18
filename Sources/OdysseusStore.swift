import Foundation
import SwiftUI

@MainActor
final class OdysseusStore: ObservableObject {
    private let conversationsKey = "odysseus.conversations.v2"
    private let memoriesKey = "odysseus.memories.v2"
    private let settingsKey = "odysseus.settings.v2"
    private let selectedConversationKey = "odysseus.selectedConversationID.v2"

    @Published var conversations: [Conversation] = []
    @Published var memories: [MemoryItem] = []
    @Published var settings = OdysseusSettings()
    @Published var selectedConversationID: UUID?

    init() {
        loadAll()

        if conversations.isEmpty {
            let starter = Conversation(title: "Odysseus")
            conversations = [starter]
            selectedConversationID = starter.id
            saveAll()
        }

        if selectedConversationID == nil {
            selectedConversationID = conversations.first?.id
        }
    }

    var currentConversation: Conversation? {
        guard let id = selectedConversationID else { return conversations.first }
        return conversations.first(where: { $0.id == id }) ?? conversations.first
    }

    var currentMessages: [ChatMessage] {
        currentConversation?.messages ?? []
    }

    func select(_ conversation: Conversation) {
        selectedConversationID = conversation.id
        saveSelectedConversation()
    }

    func newConversation() {
        let conversation = Conversation(title: "New Chat")
        conversations.insert(conversation, at: 0)
        selectedConversationID = conversation.id
        saveAll()
    }

    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }

        if conversations.isEmpty {
            let starter = Conversation(title: "Odysseus")
            conversations = [starter]
            selectedConversationID = starter.id
        } else if selectedConversationID == conversation.id {
            selectedConversationID = conversations.first?.id
        }

        saveAll()
    }

    func renameCurrentConversation(_ title: String) {
        guard let index = currentConversationIndex else { return }
        conversations[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title
        conversations[index].updatedAt = Date()
        saveAll()
    }

    func addUserMessage(text: String, images: [ImageAttachment]) {
        guard let index = currentConversationIndex else { return }

        let message = ChatMessage(role: "user", text: text, imageAttachments: images)
        conversations[index].messages.append(message)

        if conversations[index].title == "New Chat" || conversations[index].title == "Odysseus" {
            conversations[index].title = makeTitle(from: text)
        }

        conversations[index].updatedAt = Date()
        moveConversationToTop(index)
        saveAll()
    }

    func addAssistantMessage(_ text: String) {
        guard let index = currentConversationIndex else { return }

        let message = ChatMessage(role: "assistant", text: text)
        conversations[index].messages.append(message)
        conversations[index].updatedAt = Date()
        moveConversationToTop(index)
        saveAll()
    }

    func addErrorMessage(_ text: String) {
        addAssistantMessage("⚠️ " + text)
    }

    func clearCurrentConversation() {
        guard let index = currentConversationIndex else { return }
        conversations[index].messages.removeAll()
        conversations[index].updatedAt = Date()
        saveAll()
    }

    func addMemory(title: String, body: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanBody.isEmpty else { return }

        memories.insert(
            MemoryItem(
                title: cleanTitle.isEmpty ? "Memory" : cleanTitle,
                body: cleanBody
            ),
            at: 0
        )

        saveMemories()
    }

    func updateMemory(_ item: MemoryItem) {
        guard let index = memories.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.updatedAt = Date()
        memories[index] = updated
        saveMemories()
    }

    func deleteMemory(_ item: MemoryItem) {
        memories.removeAll { $0.id == item.id }
        saveMemories()
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }

    func developerPrompt() -> String {
        let enabledMemories = memories.filter { $0.enabled }

        var prompt = settings.systemPrompt

        if !enabledMemories.isEmpty {
            prompt += "\n\nSaved local memory for this user:\n"
            for memory in enabledMemories {
                prompt += "- \(memory.title): \(memory.body)\n"
            }
        }

        return prompt
    }

    func exportCurrentConversation() -> String {
        guard let conversation = currentConversation else { return "" }

        var output = "# \(conversation.title)\n\n"
        for message in conversation.messages {
            output += "\(message.role.uppercased()): \(message.text)\n\n"
            if !message.imageAttachments.isEmpty {
                output += "[\(message.imageAttachments.count) image attachment(s)]\n\n"
            }
        }
        return output
    }

    private var currentConversationIndex: Int? {
        guard let id = selectedConversationID else { return conversations.indices.first }
        return conversations.firstIndex(where: { $0.id == id }) ?? conversations.indices.first
    }

    private func moveConversationToTop(_ index: Int) {
        guard conversations.indices.contains(index) else { return }
        let conversation = conversations.remove(at: index)
        conversations.insert(conversation, at: 0)
        selectedConversationID = conversation.id
    }

    private func makeTitle(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count <= 32 {
            return cleaned.isEmpty ? "New Chat" : cleaned
        }

        return String(cleaned.prefix(32)) + "..."
    }

    private func loadAll() {
        if let data = UserDefaults.standard.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded
        }

        if let data = UserDefaults.standard.data(forKey: memoriesKey),
           let decoded = try? JSONDecoder().decode([MemoryItem].self, from: data) {
            memories = decoded
        }

        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(OdysseusSettings.self, from: data) {
            settings = decoded
        }

        if let idString = UserDefaults.standard.string(forKey: selectedConversationKey),
           let id = UUID(uuidString: idString) {
            selectedConversationID = id
        }
    }

    private func saveAll() {
        saveConversations()
        saveMemories()
        saveSettings()
        saveSelectedConversation()
    }

    private func saveConversations() {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        UserDefaults.standard.set(data, forKey: conversationsKey)
    }

    private func saveMemories() {
        guard let data = try? JSONEncoder().encode(memories) else { return }
        UserDefaults.standard.set(data, forKey: memoriesKey)
    }

    private func saveSelectedConversation() {
        UserDefaults.standard.set(selectedConversationID?.uuidString, forKey: selectedConversationKey)
    }
}
