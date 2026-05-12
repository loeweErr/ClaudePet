import Foundation
import AVFoundation

/// Pet audio: real recorded meow for `pet_meow`, TTS for arbitrary text.
/// Meow recording is bundled at Contents/Resources/meow.m4a
/// (source: Wikimedia Commons "Meow of a Siamese cat - freemaster2.wav", CC0).
final class PetAudio {

    private let synth = AVSpeechSynthesizer()
    private let cattyVoice: AVSpeechSynthesisVoice?
    private var meowPlayer: AVAudioPlayer?

    init() {
        // Priority: Meijia (zh-TW, softer) > Tingting (zh-CN, formal) > any zh > any.
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferred = ["Meijia", "Mei-Jia", "Tingting", "Ting-Ting"]
        var picked: AVSpeechSynthesisVoice?
        for name in preferred {
            picked = voices.first { $0.name.contains(name) }
            if picked != nil { break }
        }
        if picked == nil {
            picked = AVSpeechSynthesisVoice(language: "zh-TW")
                  ?? AVSpeechSynthesisVoice(language: "zh-CN")
        }
        self.cattyVoice = picked

        // Preload the meow file so first playback has no disk-read delay.
        if let url = Bundle.main.url(forResource: "meow", withExtension: "m4a") {
            do {
                meowPlayer = try AVAudioPlayer(contentsOf: url)
                meowPlayer?.prepareToPlay()
                meowPlayer?.volume = 0.95
            } catch {
                FileHandle.standardError.write(Data("[audio] meow load failed: \(error)\n".utf8))
            }
        } else {
            FileHandle.standardError.write(Data("[audio] meow.m4a not found in bundle resources\n".utf8))
        }
    }

    /// `catty: true` boosts pitch hard for cat vibe.
    /// `catty: false` plays in normal voice (long content / serious info).
    func speak(_ text: String, catty: Bool = true) {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // For very short meow-like utterances, stretch the vowel so it sounds drawn out
        // and more like a real cat (avoids the staccato robot-tone problem).
        if catty && trimmed.count <= 3 {
            trimmed = trimmed
                .replacingOccurrences(of: "喵", with: "喵呜呜")
                .replacingOccurrences(of: "~", with: "")
        }

        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = cattyVoice
        if catty {
            utterance.pitchMultiplier = 1.95          // near max (range 0.5–2.0)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
            utterance.volume = 0.9
            // Light pre-utterance pause feels less mechanical
            utterance.preUtteranceDelay = 0.05
        } else {
            utterance.volume = 0.9
        }
        synth.speak(utterance)
    }

    func meow() {
        if let p = meowPlayer {
            // Replay from start; if already playing, stop first.
            if p.isPlaying { p.stop() }
            p.currentTime = 0
            // Slight random pitch shift (0.9–1.1) via rate so repeated meows feel different.
            // (Only works if enableRate=true set on player; harmless if not.)
            p.enableRate = true
            p.rate = Float.random(in: 0.92...1.10)
            p.play()
        } else {
            // Fallback to TTS if the bundled file is missing.
            let lines = ["喵呜呜呜", "喵呜~", "咪呜呜", "喵?"]
            speak(lines.randomElement()!, catty: true)
        }
    }

    func stop() {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
    }
}
