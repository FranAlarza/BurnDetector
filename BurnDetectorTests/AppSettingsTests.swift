import Foundation
import Testing
@testable import BurnDetector

@Suite(.serialized)
struct AppSettingsTests {

    init() {
        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: "selectedSound")
    }

    @Test
    func defaultValues() {
        let settings = AppSettings()

        #expect(settings.threshold == 90)
        #expect(settings.soundEnabled == true)
        #expect(settings.selectedSound == "scream")
    }

    @Test
    func thresholdPersistsToUserDefaults() {
        let settings = AppSettings()
        settings.threshold = 75

        #expect(UserDefaults.standard.integer(forKey: "cpuThreshold") == 75)
    }

    @Test
    func soundEnabledPersistsToUserDefaults() {
        let settings = AppSettings()
        settings.soundEnabled = false

        #expect(UserDefaults.standard.bool(forKey: "soundEnabled") == false)
    }

    @Test
    func selectedSoundPersistsToUserDefaults() {
        let settings = AppSettings()
        settings.selectedSound = "sheep"

        #expect(UserDefaults.standard.string(forKey: "selectedSound") == "sheep")
    }

    @Test
    func restoresPersistedValues() {
        UserDefaults.standard.set(60, forKey: "cpuThreshold")
        UserDefaults.standard.set(false, forKey: "soundEnabled")
        UserDefaults.standard.set("sheep", forKey: "selectedSound")

        let settings = AppSettings()

        #expect(settings.threshold == 60)
        #expect(settings.soundEnabled == false)
        #expect(settings.selectedSound == "sheep")
    }

    @Test
    func fallsBackToDefaultWhenStoredSoundMissing() {
        UserDefaults.standard.set("nonexistent_sound", forKey: "selectedSound")

        let settings = AppSettings()

        #expect(settings.selectedSound == "scream")
    }

    @Test
    func validateBundledSoundExists() {
        #expect(AppSettings.validate(selectedSound: "scream") == true)
    }

    @Test
    func validateBundledSoundMissing() {
        #expect(AppSettings.validate(selectedSound: "nonexistent") == false)
    }

    @Test
    func validateCustomSoundMissingOnDisk() {
        #expect(AppSettings.validate(selectedSound: "/nonexistent/path/sound.mp3") == false)
    }
}
