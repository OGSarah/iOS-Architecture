//
//  PlaybackPresenter.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The seam through which a touch is heard: something that can strike a bell.
///
/// Keeping playback behind a protocol lets the `PlaybackPresenter` be driven in a test with
/// a silent recorder, so the timing and highlighting logic can be checked without any audio
/// hardware. The live implementation, `BellAudioEngine`, synthesises the bells.
@MainActor
protocol BellRinging: AnyObject {

    /// Prepares the audio graph to ring a given stage's bells.
    ///
    /// - Parameter stage: The stage about to be rung.
    func prepare(for stage: Stage)

    /// Strikes a single bell.
    ///
    /// - Parameters:
    ///   - bell: The bell number, with `1` the highest in pitch.
    ///   - stage: The stage, which sets how many bells span the tuned range.
    func strike(bell: Int, of stage: Stage)

    /// Silences the engine and stops any ringing decay.
    func stopAll()
}

/// Drives playback of a touch: it walks the rows at a ringing pace, strikes each bell in
/// turn, and reports which row is currently sounding.
///
/// Playback is inherently stateful and time-driven, so it lives in its own presenter that
/// the `TouchEditorPresenter` owns. It commands nothing directly: it reports progress back
/// through two callbacks, which the editor presenter forwards to the passive view as
/// `setPlaybackHighlight` and `setPlaying`.
@MainActor
final class PlaybackPresenter {

    /// Called with the index of the sounding row, or `nil` when playback stops.
    var onHighlight: ((Int?) -> Void)?

    /// Called with `true` when playback starts and `false` when it stops.
    var onPlayingChanged: ((Bool) -> Void)?

    /// The audio seam that actually makes the sound.
    private let audio: BellRinging

    /// The running playback task, if any.
    private var task: Task<Void, Never>?

    /// The gap between successive bell strikes, which sets the ringing pace.
    private let interBellDelay: Duration = .milliseconds(170)

    /// The extra gap between rows, the small pause a band leaves at each hand and back.
    private let interRowDelay: Duration = .milliseconds(120)

    /// Creates a playback presenter over an audio seam.
    ///
    /// - Parameter audio: The bell-ringing seam to strike.
    init(audio: BellRinging) {
        self.audio = audio
    }

    /// Whether playback is currently running.
    var isPlaying: Bool { task != nil }

    /// Plays a sequence of rows from the start.
    ///
    /// Any playback already running is stopped first. If the rows are empty, nothing happens.
    ///
    /// - Parameters:
    ///   - rows: The rows to ring, in order.
    ///   - stage: The stage the rows are rung at.
    func play(rows: [Row], stage: Stage) {
        stop()
        guard !rows.isEmpty else { return }

        // Report playing before preparing the audio so the control reflects the state
        // immediately, even if starting the audio engine takes a moment.
        onPlayingChanged?(true)
        audio.prepare(for: stage)

        task = Task { [weak self] in
            guard let self else { return }
            for (index, row) in rows.enumerated() {
                if Task.isCancelled { break }
                self.onHighlight?(index)
                for bell in row.bells {
                    if Task.isCancelled { break }
                    self.audio.strike(bell: bell, of: stage)
                    try? await Task.sleep(for: self.interBellDelay)
                }
                try? await Task.sleep(for: self.interRowDelay)
            }
            self.finish()
        }
    }

    /// Stops playback and clears the highlight.
    func stop() {
        guard task != nil else { return }
        task?.cancel()
        task = nil
        audio.stopAll()
        onHighlight?(nil)
        onPlayingChanged?(false)
    }

    /// Cleans up after playback runs to the end on its own.
    private func finish() {
        task = nil
        audio.stopAll()
        onHighlight?(nil)
        onPlayingChanged?(false)
    }
}
