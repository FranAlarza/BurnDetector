//
//  AppSettings.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import Foundation
import os

@Observable
final class AppSettings {

    // MARK: - Keys

    private enum Keys {
        static let threshold = "cpuThreshold"
        static let soundEnabled = "soundEnabled"
        static let selectedSound = "selectedSound"
    }

    // MARK: - Defaults

    private static let defaultThreshold = 90
    private static let defaultSoundEnabled = true
    static let defaultSelectedSound = "scream"

    // MARK: - Properties

    var threshold: Int {
        didSet { UserDefaults.standard.set(threshold, forKey: Keys.threshold) }
    }

    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    /// Stores either a bundled filename (e.g. "scream") or an absolute path for custom sounds.
    var selectedSound: String {
        didSet { UserDefaults.standard.set(selectedSound, forKey: Keys.selectedSound) }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        let logger = Logger(subsystem: "com.aweapps.Asado", category: "AppSettings")

        if defaults.object(forKey: Keys.threshold) != nil {
            self.threshold = defaults.integer(forKey: Keys.threshold)
        } else {
            self.threshold = Self.defaultThreshold
        }

        if defaults.object(forKey: Keys.soundEnabled) != nil {
            self.soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        } else {
            self.soundEnabled = Self.defaultSoundEnabled
        }

        if let stored = defaults.string(forKey: Keys.selectedSound) {
            let isValid = Self.validate(selectedSound: stored)
            if isValid {
                self.selectedSound = stored
            } else {
                logger.warning("Stored sound '\(stored)' is no longer valid, resetting to default")
                self.selectedSound = Self.defaultSelectedSound
            }
        } else {
            self.selectedSound = Self.defaultSelectedSound
        }
    }

    // MARK: - Validation

    static func validate(selectedSound: String) -> Bool {
        if selectedSound.contains("/") {
            // Custom sound — validate file exists on disk
            return FileManager.default.fileExists(atPath: selectedSound)
        } else {
            // Bundled sound — validate via Bundle
            return Bundle.main.url(forResource: selectedSound, withExtension: "mp3") != nil
        }
    }
}
