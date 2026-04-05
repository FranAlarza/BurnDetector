//
//  CustomSoundStorageService.swift
//  Asado
//
//  Created by Fran Alarza on 1/4/26.
//

import Foundation
import os

// MARK: - Protocol

protocol CustomSoundStorageServiceProtocol: Sendable {
    var storageDirectory: URL { get }
    func importSound(from source: URL) throws -> SoundOption
    func deleteSound(_ sound: SoundOption) throws
    func allCustomSounds() -> [SoundOption]
}

// MARK: - Errors

enum CustomSoundStorageError: Error, LocalizedError {
    case failedToCreateDirectory(Error)
    case failedToCopyFile(Error)
    case failedToDeleteFile(Error)

    var errorDescription: String? {
        switch self {
        case .failedToCreateDirectory(let error):
            return "Could not create sounds directory: \(error.localizedDescription)"
        case .failedToCopyFile(let error):
            return "Could not import sound file: \(error.localizedDescription)"
        case .failedToDeleteFile(let error):
            return "Could not delete sound file: \(error.localizedDescription)"
        }
    }
}

// MARK: - Implementation

final class CustomSoundStorageService: CustomSoundStorageServiceProtocol, @unchecked Sendable {

    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "CustomSoundStorage")
    private static let supportedExtensions = ["mp3", "wav", "aiff", "m4a"]

    // MARK: - Storage Directory

    var storageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Asado/Sounds", isDirectory: true)
    }

    // MARK: - Import

    func importSound(from source: URL) throws -> SoundOption {
        let directory = storageDirectory
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw CustomSoundStorageError.failedToCreateDirectory(error)
        }

        let destination = directory.appendingPathComponent(source.lastPathComponent)

        // Skip duplicate
        if FileManager.default.fileExists(atPath: destination.path) {
            let name = destination.deletingPathExtension().lastPathComponent
            return SoundOption(id: destination.path, displayName: name.capitalized, isCustom: true)
        }

        do {
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            throw CustomSoundStorageError.failedToCopyFile(error)
        }

        let name = destination.deletingPathExtension().lastPathComponent
        return SoundOption(id: destination.path, displayName: name.capitalized, isCustom: true)
    }

    // MARK: - Delete

    func deleteSound(_ sound: SoundOption) throws {
        guard sound.isCustom else { return }
        let url = URL(fileURLWithPath: sound.id)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw CustomSoundStorageError.failedToDeleteFile(error)
        }
    }

    // MARK: - List

    func allCustomSounds() -> [SoundOption] {
        let directory = storageDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return contents
            .filter { Self.supportedExtensions.contains($0.pathExtension.lowercased()) }
            .map { url in
                let name = url.deletingPathExtension().lastPathComponent
                return SoundOption(id: url.path, displayName: name.capitalized, isCustom: true)
            }
            .sorted { $0.displayName < $1.displayName }
    }
}
