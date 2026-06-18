import Foundation

struct ImageAttachment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var mimeType: String
    var base64Data: String
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var role: String
    var text: String
    var imageAttachments: [ImageAttachment] = []
    var createdAt: Date = Date()
}

struct Conversation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = "New Chat"
    var messages: [ChatMessage] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct MemoryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var enabled: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct OdysseusSettings: Codable, Equatable {
    var model: String = "gpt-5.5"
    var fallbackModel: String = "gpt-5.4-mini"
    var reasoningEffort: String = "low"
    var verbosity: String = "medium"
    var useWebSearch: Bool = false
    var maxHistoryMessages: Int = 28
    var systemPrompt: String =
    """
    You are Odysseus Mobile, Maddox's standalone iPhone assistant.
    Be direct, useful, practical, and technically sharp.
    Help with coding, iPhone app development, troubleshooting, writing, planning, dating-message rewrites, school, finance, and personal workflows.
    Do not pretend to have access to the user's phone data unless it has been pasted, typed, attached, or stored in local app memory.
    """
}
