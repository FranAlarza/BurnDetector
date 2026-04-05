//
//  SoundOption.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import Foundation

struct SoundOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let isCustom: Bool

    // MARK: - URL Resolution

    var url: URL? {
        if isCustom {
            let fileURL = URL(fileURLWithPath: id)
            return FileManager.default.fileExists(atPath: id) ? fileURL : nil
        } else {
            return Bundle.main.url(forResource: id, withExtension: "mp3")
        }
    }

    // MARK: - Discovery

    static func allBundled() -> [SoundOption] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
            return [fallback]
        }

        let options = urls
            .map { url in
                let name = url.deletingPathExtension().lastPathComponent
                return SoundOption(id: name, displayName: name.capitalized, isCustom: false)
            }
            .sorted { $0.displayName < $1.displayName }

        return options.isEmpty ? [fallback] : options
    }

    static func allCustom(using storage: CustomSoundStorageServiceProtocol) -> [SoundOption] {
        storage.allCustomSounds()
    }

    static func all(using storage: CustomSoundStorageServiceProtocol) -> [SoundOption] {
        let bundled = allBundled()
        let custom = allCustom(using: storage)
        return (bundled + custom).sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Private

    static let fallback = SoundOption(id: "scream", displayName: "Scream", isCustom: false)
}
