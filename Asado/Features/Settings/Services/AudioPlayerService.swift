//
//  AudioPlayerService.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import AVFoundation
import Foundation
import os

// MARK: - Protocol

protocol AudioPlayerServiceProtocol: Sendable {
    func playSound(url: URL) async
}

// MARK: - Implementation

final class AudioPlayerService: AudioPlayerServiceProtocol, @unchecked Sendable {

    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "AudioPlayer")
    private var player: AVAudioPlayer?

    func playSound(url: URL) async {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            self.player = player
            player.play()
        } catch {
            logger.error("Failed to play sound at '\(url.lastPathComponent)': \(error.localizedDescription)")
        }
    }
}
