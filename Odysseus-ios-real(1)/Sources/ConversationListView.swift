import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject private var store: OdysseusStore
    @Environment(\.dismiss) private var dismiss

    @State private var renameText = ""
    @State private var showingRename = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        store.newConversation()
                        dismiss()
                    } label: {
                        Label("New Chat", systemImage: "plus.circle.fill")
                    }
                }

                Section("Chats") {
                    ForEach(store.conversations) { conversation in
                        Button {
                            store.select(conversation)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title)
                                    .font(.headline)

                                Text("\(conversation.messages.count) messages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contextMenu {
                            Button("Rename") {
                                store.select(conversation)
                                renameText = conversation.title
                                showingRename = true
                            }

                            Button("Delete", role: .destructive) {
                                store.deleteConversation(conversation)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Rename Chat", isPresented: $showingRename) {
                TextField("Title", text: $renameText)

                Button("Save") {
                    store.renameCurrentConversation(renameText)
                }

                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
