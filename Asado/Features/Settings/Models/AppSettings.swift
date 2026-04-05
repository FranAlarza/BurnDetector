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
        static let diskThresholdGB = "diskThresholdGB"
        static let diskSoundEnabled = "diskSoundEnabled"
        static let diskSelectedSound = "diskSelectedSound"
    }

    // MARK: - Defaults

    private static let defaultThreshold = 90
    private static let defaultSoundEnabled = true
    static let defaultSelectedSound = "scream"
    private static let defaultDiskThresholdGB = 50
    private static let defaultDiskSoundEnabled = true
    static let defaultDiskSelectedSound = "scream"

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

    var diskThresholdGB: Int {
        didSet { UserDefaults.standard.set(diskThresholdGB, forKey: Keys.diskThresholdGB) }
    }

    var diskSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(diskSoundEnabled, forKey: Keys.diskSoundEnabled) }
    }

    /// Stores either a bundled filename (e.g. "scream") or an absolute path for custom sounds.
    var diskSelectedSound: String {
        didSet { UserDefaults.standard.set(diskSelectedSound, forKey: Keys.diskSelectedSound) }
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

        if defaults.object(forKey: Keys.diskThresholdGB) != nil {
            self.diskThresholdGB = defaults.integer(forKey: Keys.diskThresholdGB)
        } else {
            self.diskThresholdGB = Self.defaultDiskThresholdGB
        }

        if defaults.object(forKey: Keys.diskSoundEnabled) != nil {
            self.diskSoundEnabled = defaults.bool(forKey: Keys.diskSoundEnabled)
        } else {
            self.diskSoundEnabled = Self.defaultDiskSoundEnabled
        }

        if let stored = defaults.string(forKey: Keys.diskSelectedSound) {
            let isValid = Self.validate(selectedSound: stored)
            if isValid {
                self.diskSelectedSound = stored
            } else {
                logger.warning("Stored disk sound '\(stored)' is no longer valid, resetting to default")
                self.diskSelectedSound = Self.defaultDiskSelectedSound
            }
        } else {
            self.diskSelectedSound = Self.defaultDiskSelectedSound
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
