# Odysseus iOS

Real standalone iPhone build of Odysseus Mobile.

## Bundle ID

`com.s9yvmzf2s7afk.odysseus`

Do not change the bundle ID unless you intentionally want Apple/Sideloadly to treat it as a separate app.

## Features

- Native SwiftUI app
- Runs independently on iPhone
- No Windows backend required
- No Safari/PWA required
- OpenAI Responses API client
- API key stored in iOS Keychain
- Multiple local conversations
- Local memory injection
- Model, reasoning, verbosity, web-search toggle
- Image attachments through Photos picker
- Chat export/share
- GitHub Actions IPA build
- Sideloadly install flow

## Build

1. Upload the repo contents to GitHub.
2. Open Actions.
3. Run `Build iOS IPA`.
4. Download the `Odysseus-IPA` artifact.
5. Extract it.
6. Install `Odysseus.ipa` with Sideloadly.
