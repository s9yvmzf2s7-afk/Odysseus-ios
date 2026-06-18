import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser {
                Spacer(minLength: 36)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isUser ? "You" : "Odysseus")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !message.imageAttachments.isEmpty {
                        Text("\(message.imageAttachments.count) image(s)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.body)
                        .textSelection(.enabled)
                }

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(isUser ? Color.accentColor.opacity(0.16) : Color.gray.opacity(0.14))
            .cornerRadius(16)

            if !isUser {
                Spacer(minLength: 36)
            }
        }
    }
}

struct ExportView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: .constant(text))
                    .font(.system(.body, design: .monospaced))
                    .padding()

                ShareLink(item: text) {
                    Label("Share / Copy Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Export Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
