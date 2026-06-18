import Foundation

final class OpenAIClient {
    struct APIError: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    func send(messages: [ChatMessage], apiKey: String, settings: OdysseusSettings, developerPrompt: String) async throws -> String {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanKey.isEmpty else {
            throw APIError(message: "Missing API key. Open Settings and save your OpenAI API key.")
        }

        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw APIError(message: "Bad OpenAI URL.")
        }

        var inputItems: [[String: Any]] = [
            [
                "role": "developer",
                "content": [
                    [
                        "type": "input_text",
                        "text": developerPrompt
                    ]
                ]
            ]
        ]

        let recentMessages = Array(messages.suffix(settings.maxHistoryMessages))

        for message in recentMessages {
            var contentParts: [[String: Any]] = []

            if !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                contentParts.append([
                    "type": message.role == "assistant" ? "output_text" : "input_text",
                    "text": message.text
                ])
            }

            if message.role == "user" {
                for image in message.imageAttachments {
                    contentParts.append([
                        "type": "input_image",
                        "image_url": "data:\(image.mimeType);base64,\(image.base64Data)"
                    ])
                }
            }

            if contentParts.isEmpty {
                continue
            }

            inputItems.append([
                "role": message.role,
                "content": contentParts
            ])
        }

        var body: [String: Any] = [
            "model": settings.model,
            "input": inputItems,
            "reasoning": [
                "effort": settings.reasoningEffort
            ],
            "text": [
                "verbosity": settings.verbosity
            ]
        ]

        if settings.useWebSearch {
            body["tools"] = [
                [
                    "type": "web_search_preview"
                ]
            ]
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.timeoutInterval = 120
        request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError(message: "OpenAI did not return an HTTP response.")
        }

        if !(200...299).contains(http.statusCode) {
            let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError(message: "OpenAI error \(http.statusCode): \(raw)")
        }

        return try extractText(from: data)
    }

    private func extractText(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError(message: "Could not parse OpenAI response.")
        }

        if let outputText = json["output_text"] as? String {
            let trimmed = outputText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        var collected = ""

        if let output = json["output"] as? [[String: Any]] {
            for item in output {
                if let content = item["content"] as? [[String: Any]] {
                    for part in content {
                        if let text = part["text"] as? String {
                            collected += text
                        }

                        if let outputText = part["output_text"] as? String {
                            collected += outputText
                        }
                    }
                }
            }
        }

        let trimmed = collected.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            throw APIError(message: "OpenAI responded, but this app could not find response text.")
        }

        return trimmed
    }
}
