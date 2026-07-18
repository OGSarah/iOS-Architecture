//
//  BellAudioEngine.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import AVFoundation

/// The live bell sound, synthesised on the fly with `AVAudioEngine`.
///
/// The project ships no audio files and has no network, so each bell is generated as a short
/// decaying tone built from a fundamental and a few inharmonic partials, which gives a
/// struck-metal character without a recording. Buffers are cached per bell, and a small pool
/// of player nodes lets successive strikes overlap as their tails decay, the way a real ring
/// of bells sounds.
///
/// This is infrastructure behind the `BellRinging` seam, so the `PlaybackPresenter` can be
/// tested against a silent stub instead.
@MainActor
final class BellAudioEngine: BellRinging {

    /// The underlying audio engine.
    private let engine = AVAudioEngine()

    /// A pool of player nodes cycled through so overlapping strikes each get a voice.
    private var players: [AVAudioPlayerNode] = []

    /// The next player node to use, advanced on every strike.
    private var nextPlayer = 0

    /// Cached tone buffers, keyed by the rounded frequency they were built for.
    private var buffers: [Int: AVAudioPCMBuffer] = [:]

    /// The mono, floating-point format the engine renders in.
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    /// The number of overlapping voices.
    private let voiceCount = 8

    /// Whether the engine has been started.
    private var isRunning = false

    /// Creates the engine and wires up its player-node pool.
    init() {
        for _ in 0..<voiceCount {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            try? engine.connectNode(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
    }

    // MARK: BellRinging

    func prepare(for stage: Stage) {
        guard !isRunning else { return }
        configureAudioSession()
        do {
            try engine.start()
            for player in players { try player.playAudio() }
            isRunning = true
        } catch {
            // Audio is a nicety, not a requirement: if it cannot start, playback stays silent.
            isRunning = false
        }
    }

    func strike(bell: Int, of stage: Stage) {
        guard isRunning else { return }
        let buffer = toneBuffer(forBell: bell, of: stage)
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    func stopAll() {
        guard isRunning else { return }
        for player in players { player.stop(); try? player.playAudio() }
    }

    // MARK: Private

    /// Configures the shared audio session for playback.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    /// The frequency for a bell, with bell one the highest, descending a major scale.
    ///
    /// - Parameters:
    ///   - bell: The bell number.
    ///   - stage: The stage, used to place the whole ring in a comfortable range.
    /// - Returns: The fundamental frequency in hertz.
    private func frequency(forBell bell: Int, of stage: Stage) -> Double {
        // Semitone offsets of a descending major scale, so the treble is highest.
        let majorScale = [0, -2, -4, -5, -7, -9, -11, -12]
        let index = min(bell - 1, majorScale.count - 1)
        let base = 987.77 // B5, a bright treble.
        return base * pow(2.0, Double(majorScale[index]) / 12.0)
    }

    /// Returns a cached decaying tone buffer for a bell, building it on first use.
    private func toneBuffer(forBell bell: Int, of stage: Stage) -> AVAudioPCMBuffer {
        let freq = frequency(forBell: bell, of: stage)
        let key = Int(freq.rounded())
        if let cached = buffers[key] { return cached }

        let duration = 0.7
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]

        // A struck-bell timbre: a fundamental plus a few inharmonic partials, each with its
        // own exponential decay so the tone rings and fades rather than holding flat.
        let partials: [(ratio: Double, gain: Double, decay: Double)] = [
            (1.0, 1.0, 4.5),
            (2.01, 0.6, 5.5),
            (2.41, 0.35, 6.5),
            (3.02, 0.2, 7.5)
        ]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / format.sampleRate
            var value = 0.0
            for partial in partials {
                value += partial.gain * sin(2.0 * .pi * freq * partial.ratio * t) * exp(-t * partial.decay)
            }
            samples[frame] = Float(value * 0.18)
        }

        buffers[key] = buffer
        return buffer
    }
}
