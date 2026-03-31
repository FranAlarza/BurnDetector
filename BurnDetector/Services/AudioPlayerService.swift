import AVFoundation
import os

// MARK: - Protocol

protocol AudioPlayerServiceProtocol: Sendable {
    func playScream() async
}

// MARK: - Implementation

final class AudioPlayerService: AudioPlayerServiceProtocol, @unchecked Sendable {

    private let logger = Logger(subsystem: "com.aweapps.BurnDetector", category: "AudioPlayer")
    private var player: AVAudioPlayer?

    func playScream() async {
        guard let url = Bundle.main.url(forResource: "scream", withExtension: "mp3") else {
            logger.error("Scream audio file not found in bundle")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            self.player = player
            player.play()
        } catch {
            logger.error("Failed to play scream sound: \(error.localizedDescription)")
        }
    }
}
