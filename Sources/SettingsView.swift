import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: OdysseusStore

    private let apiKeyName = "openai_api_key"

    @State private var apiKey = ""
    @State private var status = ""

    private let efforts = ["minimal", "low", "medium", "high"]
    private let verbosityOptions = ["low", "medium", "high"]

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI") {
                    SecureField("API key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Save API Key") {
                        saveAPIKey()
                    }

                    Button("Delete API Key", role: .destructive) {
                        KeychainStore.delete(apiKeyName)
                        apiKey = ""
                        status = "API key deleted."
                    }

                    if !status.isEmpty {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("The key is stored in this iPhone's Keychain, not in GitHub.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Model") {
                    TextField("Model", text: Binding(
                        get: { store.settings.model },
                        set: {
                            store.settings.model = $0
                            store.saveSettings()
                        }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Picker("Reasoning", selection: Binding(
                        get: { store.settings.reasoningEffort },
                        set: {
                            store.settings.reasoningEffort = $0
                            store.saveSettings()
                        }
                    )) {
                        ForEach(efforts, id: \.self) { Text($0) }
                    }

                    Picker("Verbosity", selection: Binding(
                        get: { store.settings.verbosity },
                        set: {
                            store.settings.verbosity = $0
                            store.saveSettings()
                        }
                    )) {
                        ForEach(verbosityOptions, id: \.self) { Text($0) }
                    }

                    Toggle("Use web search tool", isOn: Binding(
                        get: { store.settings.useWebSearch },
                        set: {
                            store.settings.useWebSearch = $0
                            store.saveSettings()
                        }
                    ))

                    Stepper("History: \(store.settings.maxHistoryMessages) messages", value: Binding(
                        get: { store.settings.maxHistoryMessages },
                        set: {
                            store.settings.maxHistoryMessages = $0
                            store.saveSettings()
                        }
                    ), in: 4...60)
                }

                Section("System Prompt") {
                    TextEditor(text: Binding(
                        get: { store.settings.systemPrompt },
                        set: {
                            store.settings.systemPrompt = $0
                            store.saveSettings()
                        }
                    ))
                    .frame(minHeight: 180)
                }

                Section("Quick Model Presets") {
                    Button("GPT-5.5") {
                        store.settings.model = "gpt-5.5"
                        store.saveSettings()
                    }

                    Button("GPT-5.4 mini") {
                        store.settings.model = "gpt-5.4-mini"
                        store.saveSettings()
                    }
                }

                Section("App Identity") {
                    Text("Bundle ID")
                    Text("com.s9yvmzf2s7afk.odysseus")
                        .font(.caption)
                        .textSelection(.enabled)

                    Text("Keep this unchanged so Sideloadly updates the same app instead of registering a new app identity.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                let existing = KeychainStore.load(apiKeyName)
                if existing.isEmpty {
                    status = "No API key saved."
                } else {
                    apiKey = existing
                    status = "API key saved."
                }
            }
        }
    }

    private func saveAPIKey() {
        let clean = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !clean.isEmpty else {
            status = "Paste an API key first."
            return
        }

        do {
            try KeychainStore.save(clean, for: apiKeyName)
            status = "API key saved."
        } catch {
            status = error.localizedDescription
        }
    }
}
