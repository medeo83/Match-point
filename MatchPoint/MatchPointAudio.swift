import Foundation
import AVFoundation

final class MatchPointAudio {
    static let shared = MatchPointAudio()
    var suonoAbilitato = true

    private var playerPunto: AVAudioPlayer?
    private var playerAnnulla: AVAudioPlayer?
    private var playerSilenzioso: AVAudioPlayer?

    private init() {
        playerPunto = caricaAudio("matchpoint_punto")
        playerAnnulla = caricaAudio("matchpoint_annulla")

        preparaAudioSilenzioso()

        print("MATCH POINT AUDIO: Lettori preparati")
    }
    
    private func preparaAudioSilenzioso() {
        guard let url = Bundle.main.url(
            forResource: "matchpoint_punto",
            withExtension: "wav"
        ) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0
            player.numberOfLoops = -1
            player.prepareToPlay()
            playerSilenzioso = player
            player.play()
        } catch {
            print("MATCH POINT: Errore audio silenzioso = \(error)")
        }
    }

    private func caricaAudio(_ nome: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(
            forResource: nome,
            withExtension: "wav"
        ) else {
            print("MATCH POINT: File audio non trovato: \(nome)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.3
            player.prepareToPlay()
            return player
        } catch {
            print("MATCH POINT: Errore caricamento audio: \(error)")
            return nil
        }
    }

func suonaPunto() {
    guard suonoAbilitato else { return }
    guard let player = playerPunto else { return }

    if player.isPlaying {
        player.stop()
    }

    player.currentTime = 0
    player.prepareToPlay()

    let avviato = player.play()

    print("MATCH POINT AUDIO: Riproduzione avviata = \(avviato)")
}
    func suonaAnnulla() {
        guard suonoAbilitato else { return }
        playerAnnulla?.currentTime = 0
        playerAnnulla?.play()
    }
}
