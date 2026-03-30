import SwiftUI
import CoreAudio
import Sparkle

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var updater: SPUUpdater
    @State private var inputDevices: [(id: AudioDeviceID, name: String)] = []

    var body: some View {
        Form {
            Section("Output Folders") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meetings")
                            .font(.system(size: 12, weight: .medium))
                        Text(settings.vaultMeetingsPath.isEmpty ? "No folder selected" : settings.vaultMeetingsPath)
                            .font(.system(size: 11))
                            .foregroundStyle(settings.vaultMeetingsPath.isEmpty ? .tertiary : .secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button("Choose...") {
                        chooseFolder(message: "Choose the folder for meeting transcripts") { path in
                            settings.vaultMeetingsPath = path
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Memos")
                            .font(.system(size: 12, weight: .medium))
                        Text(settings.vaultVoicePath.isEmpty ? "No folder selected" : settings.vaultVoicePath)
                            .font(.system(size: 11))
                            .foregroundStyle(settings.vaultVoicePath.isEmpty ? .tertiary : .secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button("Choose...") {
                        chooseFolder(message: "Choose the folder for voice memo transcripts") { path in
                            settings.vaultVoicePath = path
                        }
                    }
                }
            }

            Section("Idioma / Language") {
                Picker("Motor ASR", selection: $settings.asrEngine) {
                    ForEach(AsrEngine.allCases, id: \.self) { engine in
                        Text(engine.rawValue).tag(engine)
                    }
                }
                .font(.system(size: 12))

                if settings.asrEngine == .qwen3 {
                    Picker("Idioma", selection: $settings.transcriptionLanguage) {
                        ForEach(TranscriptionLanguage.all) { lang in
                            Text(lang.name).tag(lang.id)
                        }
                    }
                    .font(.system(size: 12))

                    Text("Qwen3 fuerza la transcripción al idioma seleccionado. Ideal para reuniones donde todos hablan el mismo idioma.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Parakeet auto-detecta el idioma por segmento. Puede mezclar idiomas en la misma sesión.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Audio Input") {
                Picker("Microphone", selection: $settings.inputDeviceID) {
                    Text("System Default").tag(AudioDeviceID(0))
                    ForEach(inputDevices, id: \.id) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                .font(.system(size: 12))
            }

            Section("Privacy") {
                Toggle("Hide from screen sharing", isOn: $settings.hideFromScreenShare)
                    .font(.system(size: 12))
                Text("When enabled, the app is invisible during screen sharing and recording.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("Updates") {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))
                .font(.system(size: 12))
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 420)
        .onAppear {
            inputDevices = MicCapture.availableInputDevices()
        }
    }

    private func chooseFolder(message: String, onSelect: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = message

        if panel.runModal() == .OK, let url = panel.url {
            onSelect(url.path)
        }
    }
}
