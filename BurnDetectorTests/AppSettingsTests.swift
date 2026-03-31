import Foundation
import Testing
@testable import BurnDetector

@Suite(.serialized)
struct AppSettingsTests {

    init() {
        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
    }

    @Test
    func defaultValues() {
        let settings = AppSettings()

        #expect(settings.threshold == 90)
        #expect(settings.soundEnabled == true)
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
    func restoresPersistedValues() {
        UserDefaults.standard.set(60, forKey: "cpuThreshold")
        UserDefaults.standard.set(false, forKey: "soundEnabled")

        let settings = AppSettings()

        #expect(settings.threshold == 60)
        #expect(settings.soundEnabled == false)
    }
}
