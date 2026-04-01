import Foundation
import Testing
@testable import BurnDetector

@Suite(.serialized)
struct CustomSoundStorageServiceTests {

    private var tempDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("BurnDetectorTests/Sounds", isDirectory: true)
    }

    private func makeSUT() -> CustomSoundStorageService {
        // We use the real service but override nothing — tests use temp files
        CustomSoundStorageService()
    }

    private func makeTempAudioFile(named name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("BurnDetectorTestSources")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent(name)
        // Write dummy data (not real audio, but enough for copy tests)
        try Data("fake audio".utf8).write(to: file)
        return file
    }

    init() throws {
        // Clean storage directory before each test
        let sut = CustomSoundStorageService()
        try? FileManager.default.removeItem(at: sut.storageDirectory)
    }

    @Test
    func importSoundCopiesFileToStorage() throws {
        let sut = CustomSoundStorageService()
        let source = try makeTempAudioFile(named: "test_sound.mp3")
        defer { try? FileManager.default.removeItem(at: source) }

        let option = try sut.importSound(from: source)

        let destination = sut.storageDirectory.appendingPathComponent("test_sound.mp3")
        #expect(FileManager.default.fileExists(atPath: destination.path))
        #expect(option.isCustom == true)
        #expect(option.displayName == "Test_sound")
    }

    @Test
    func importSoundSkipsDuplicate() throws {
        let sut = CustomSoundStorageService()
        let source = try makeTempAudioFile(named: "dup_sound.mp3")
        defer { try? FileManager.default.removeItem(at: source) }

        let first = try sut.importSound(from: source)
        let second = try sut.importSound(from: source)

        #expect(first.id == second.id)
        let sounds = sut.allCustomSounds()
        #expect(sounds.count == 1)
    }

    @Test
    func deleteSoundRemovesFile() throws {
        let sut = CustomSoundStorageService()
        let source = try makeTempAudioFile(named: "del_sound.mp3")
        defer { try? FileManager.default.removeItem(at: source) }

        let option = try sut.importSound(from: source)
        try sut.deleteSound(option)

        #expect(!FileManager.default.fileExists(atPath: option.id))
    }

    @Test
    func allCustomSoundsReturnsImportedSounds() throws {
        let sut = CustomSoundStorageService()
        let source1 = try makeTempAudioFile(named: "alpha.mp3")
        let source2 = try makeTempAudioFile(named: "beta.mp3")
        defer {
            try? FileManager.default.removeItem(at: source1)
            try? FileManager.default.removeItem(at: source2)
        }

        _ = try sut.importSound(from: source1)
        _ = try sut.importSound(from: source2)

        let sounds = sut.allCustomSounds()
        #expect(sounds.count == 2)
        #expect(sounds.allSatisfy { $0.isCustom })
    }

    @Test
    func allCustomSoundsReturnsEmptyWhenNoSounds() {
        let sut = CustomSoundStorageService()
        let sounds = sut.allCustomSounds()
        #expect(sounds.isEmpty)
    }
}
