import Foundation
import Testing
@testable import Asado

@Suite(.serialized)
struct AppSettingsTests {

    init() {
        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: "selectedSound")
        UserDefaults.standard.removeObject(forKey: "diskThresholdGB")
        UserDefaults.standard.removeObject(forKey: "diskSoundEnabled")
        UserDefaults.standard.removeObject(forKey: "diskSelectedSound")
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

    // MARK: - Disk properties

    @Test
    func diskDefaultValues() {
        let settings = AppSettings()

        #expect(settings.diskThresholdGB == 50)
        #expect(settings.diskSoundEnabled == true)
        #expect(settings.diskSelectedSound == "scream")
    }

    @Test
    func diskThresholdPersistsToUserDefaults() {
        let settings = AppSettings()
        settings.diskThresholdGB = 20

        #expect(UserDefaults.standard.integer(forKey: "diskThresholdGB") == 20)
    }

    @Test
    func diskSoundEnabledPersistsToUserDefaults() {
        let settings = AppSettings()
        settings.diskSoundEnabled = false

        #expect(UserDefaults.standard.bool(forKey: "diskSoundEnabled") == false)
    }

    @Test
    func diskSelectedSoundPersistsToUserDefaults() {
        let settings = AppSettings()
        settings.diskSelectedSound = "sheep"

        #expect(UserDefaults.standard.string(forKey: "diskSelectedSound") == "sheep")
    }

    @Test
    func diskRestoresPersistedValues() {
        UserDefaults.standard.set(30, forKey: "diskThresholdGB")
        UserDefaults.standard.set(false, forKey: "diskSoundEnabled")
        UserDefaults.standard.set("sheep", forKey: "diskSelectedSound")

        let settings = AppSettings()

        #expect(settings.diskThresholdGB == 30)
        #expect(settings.diskSoundEnabled == false)
        #expect(settings.diskSelectedSound == "sheep")
    }

    @Test
    func diskFallsBackToDefaultWhenStoredSoundMissing() {
        UserDefaults.standard.set("nonexistent_sound", forKey: "diskSelectedSound")

        let settings = AppSettings()

        #expect(settings.diskSelectedSound == "scream")
    }
}
