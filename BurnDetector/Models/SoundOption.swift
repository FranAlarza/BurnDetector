//
//  SoundOption.swift
//  BurnDetector
//
//  Created by Fran Alarza on 31/3/26.
//

import Foundation

struct SoundOption: Identifiable, Hashable {
    let id: String
    let displayName: String

    // MARK: - Bundle Discovery

    static func allBundled() -> [SoundOption] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
            return [fallback]
        }

        let options = urls
            .map { url in
                let name = url.deletingPathExtension().lastPathComponent
                return SoundOption(id: name, displayName: name.capitalized)
            }
            .sorted { $0.displayName < $1.displayName }

        return options.isEmpty ? [fallback] : options
    }

    // MARK: - Private

    private static let fallback = SoundOption(id: "scream", displayName: "Scream")
}
