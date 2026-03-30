import AppKit
import Foundation
import Observation
import CoreAudio

enum SessionType: String {
    case callCapture
    case voiceMemo
}

/// ASR engine selection. Qwen3 supports forced language; Parakeet uses auto-detect.
enum AsrEngine: String, CaseIterable {
    case qwen3 = "Qwen3 (forzar idioma)"
    case parakeet = "Parakeet (auto-detectar)"
}

/// Supported languages for the Qwen3 ASR engine.
struct TranscriptionLanguage: Identifiable, Hashable {
    let id: String   // ISO code
    let name: String // Display name

    static let all: [TranscriptionLanguage] = [
        .init(id: "es", name: "Español"),
        .init(id: "en", name: "English"),
        .init(id: "pt", name: "Português"),
        .init(id: "fr", name: "Français"),
        .init(id: "de", name: "Deutsch"),
        .init(id: "it", name: "Italiano"),
    ]
}

@Observable
@MainActor
final class AppSettings {
    var transcriptionLocale: String {
        didSet { UserDefaults.standard.set(transcriptionLocale, forKey: "transcriptionLocale") }
    }

    /// Stored as the AudioDeviceID integer. 0 means "use system default".
    var inputDeviceID: AudioDeviceID {
        didSet { UserDefaults.standard.set(Int(inputDeviceID), forKey: "inputDeviceID") }
    }

    var vaultMeetingsPath: String {
        didSet { UserDefaults.standard.set(vaultMeetingsPath, forKey: "vaultMeetingsPath") }
    }

    var vaultVoicePath: String {
        didSet { UserDefaults.standard.set(vaultVoicePath, forKey: "vaultVoicePath") }
    }

    /// ASR engine: qwen3 (forced language) or parakeet (auto-detect)
    var asrEngine: AsrEngine {
        didSet { UserDefaults.standard.set(asrEngine.rawValue, forKey: "asrEngine") }
    }

    /// Language code for Qwen3 forced transcription (ISO 639-1)
    var transcriptionLanguage: String {
        didSet { UserDefaults.standard.set(transcriptionLanguage, forKey: "transcriptionLanguage") }
    }

    /// When true, all app windows are invisible to screen sharing / recording.
    var hideFromScreenShare: Bool {
        didSet {
            UserDefaults.standard.set(hideFromScreenShare, forKey: "hideFromScreenShare")
            applyScreenShareVisibility()
        }
    }

    init() {
        let defaults = UserDefaults.standard
        self.transcriptionLocale = defaults.string(forKey: "transcriptionLocale") ?? "es-CO"
        self.asrEngine = AsrEngine(rawValue: defaults.string(forKey: "asrEngine") ?? "") ?? .qwen3
        self.transcriptionLanguage = defaults.string(forKey: "transcriptionLanguage") ?? "es"
        self.inputDeviceID = AudioDeviceID(defaults.integer(forKey: "inputDeviceID"))
        self.vaultMeetingsPath = defaults.string(forKey: "vaultMeetingsPath") ?? NSString("~/Library/CloudStorage/OneDrive-gecofiin/TRANSCRIPCIONES/Inbox").expandingTildeInPath
        self.vaultVoicePath = defaults.string(forKey: "vaultVoicePath") ?? NSString("~/Library/CloudStorage/OneDrive-gecofiin/TRANSCRIPCIONES/Voice").expandingTildeInPath
        // Default to true (hidden) if key has never been set
        if defaults.object(forKey: "hideFromScreenShare") == nil {
            self.hideFromScreenShare = true
        } else {
            self.hideFromScreenShare = defaults.bool(forKey: "hideFromScreenShare")
        }
    }

    /// Apply current screen-share visibility to all app windows.
    func applyScreenShareVisibility() {
        let type: NSWindow.SharingType = hideFromScreenShare ? .none : .readOnly
        for window in NSApp.windows {
            window.sharingType = type
        }
    }

    var vaultMeetingsURL: URL? {
        guard !vaultMeetingsPath.isEmpty else { return nil }
        return URL(fileURLWithPath: vaultMeetingsPath)
    }

    var vaultVoiceURL: URL? {
        guard !vaultVoicePath.isEmpty else { return nil }
        return URL(fileURLWithPath: vaultVoicePath)
    }

    var locale: Locale {
        Locale(identifier: transcriptionLocale)
    }
}
