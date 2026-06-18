import SwiftUI

struct MemoryView: View {
    @EnvironmentObject private var store: OdysseusStore

    @State private var title = ""
    @State private var bodyText = ""
    @State private var editingItem: MemoryItem?

    var body: some View {
        NavigationStack {
            List {
                Section("Add Memory") {
                    TextField("Title", text: $title)
                    TextField("Memory body", text: $bodyText, axis: .vertical)
                        .lineLimit(2...6)

                    Button("Save Memory") {
                        store.addMemory(title: title, body: bodyText)
                        title = ""
                        bodyText = ""
                    }
                    .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Saved Memory") {
                    if store.memories.isEmpty {
                        Text("No local memory yet.")
                            .foregroundColor(.secondary)
                    }

                    ForEach(store.memories) { memory in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(memory.title)
                                        .font(.headline)
                                    Text(memory.body)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: binding(for: memory))
                                    .labelsHidden()
                            }

                            HStack {
                                Button("Edit") {
                                    editingItem = memory
                                }
                                .buttonStyle(.bordered)

                                Button("Delete", role: .destructive) {
                                    store.deleteMemory(memory)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Memory")
            .sheet(item: $editingItem) { item in
                MemoryEditView(item: item)
            }
        }
    }

    private func binding(for memory: MemoryItem) -> Binding<Bool> {
        Binding(
            get: {
                store.memories.first(where: { $0.id == memory.id })?.enabled ?? false
            },
            set: { newValue in
                guard var updated = store.memories.first(where: { $0.id == memory.id }) else { return }
                updated.enabled = newValue
                store.updateMemory(updated)
            }
        )
    }
}

struct MemoryEditView: View {
    @EnvironmentObject private var store: OdysseusStore
    @Environment(\.dismiss) private var dismiss

    @State var item: MemoryItem

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $item.title)
                TextField("Memory", text: $item.body, axis: .vertical)
                    .lineLimit(4...10)
                Toggle("Enabled", isOn: $item.enabled)
            }
            .navigationTitle("Edit Memory")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        store.updateMemory(item)
                        dismiss()
                    }
                }
            }
        }
    }
}
