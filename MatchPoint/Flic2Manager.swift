//
//  Flic2Manager.swift.swift
//  MatchPoint
//
//  Created by Medeo Pirondini on 07/11/2026.
//

import Foundation
import flic2lib
import Observation

@Observable
final class Flic2Manager: NSObject, FLICManagerDelegate, FLICButtonDelegate {
    
    func manager(_ manager: FLICManager, didUpdateState state: FLICManagerState) {
        print("MATCH POINT FLIC 2: Stato manager = \(state.rawValue)")
    }
    
    func managerDidRestoreState(_ manager: FLICManager) {
        let pulsanti = manager.buttons()
        
        print("MATCH POINT FLIC 2: Ripristino completato")
        print("MATCH POINT FLIC 2: Pulsanti associati = \(pulsanti.count)")
        
        if let button = pulsanti.first {
            nomePulsante = button.name ?? "Flic 2"
            button.connect()
            flicPronto = button.isReady
            flicInConnessione = !button.isReady &&
                button.state == .connecting
            print("MATCH POINT FLIC 2: Riconnessione richiesta")
            print("MATCH POINT FLIC 2: Stato pulsante = \(button.state)")
            print("MATCH POINT FLIC 2: Pronto = \(button.isReady)")
            print("MATCH POINT FLIC 2: Recuperato \(nomePulsante)")
        }
    }
    
    func manager(_ manager: FLICManager, didUpdate state: FLICManagerState) {
        
    }
    
    func buttonDidConnect(_ button: FLICButton) {
        print("MATCH POINT FLIC 2: Bluetooth connesso!")
        print("MATCH POINT FLIC 2: Pronto = \(button.isReady)")
    }
    
    func buttonIsReady(_ button: FLICButton) {
        DispatchQueue.main.async {
            self.nomePulsante = button.name ?? "Flic 2"
            self.flicPronto = true
            self.flicInConnessione = false
        }
        
        print("MATCH POINT FLIC 2: Pulsante pronto!")
    }
    
    func button(_ button: FLICButton, didDisconnectWithError error: (any Error)?) {
        DispatchQueue.main.async {
            self.flicPronto = false
            self.flicInConnessione = button.state == .connecting
        }

        print("MATCH POINT FLIC 2: Pulsante disconnesso")
        print("MATCH POINT FLIC 2: Stato dopo disconnessione = \(button.state)")
        print("MATCH POINT FLIC 2: Errore = \(String(describing: error))")
    }
    
    func button(_ button: FLICButton, didFailToConnectWithError error: (any Error)?) {
        print("MATCH POINT FLIC 2: Connessione fallita")
        print("MATCH POINT FLIC 2: Errore = \(String(describing: error))")
    }
    
    
    static let shared = Flic2Manager()
    var nomePulsante = "Nessun Flic 2 associato"
    var flicPronto = false
    var flicInConnessione = false
    var modalitaDuePulsanti = false
    var onPuntoA: (() -> Void)?
    var onPuntoB: (() -> Void)?
    var onAnnulla: (() -> Void)?
    private override init() {
        super.init()
    }
    func avviaFlic2() {
        FLICManager.configure(
            with: self,
            buttonDelegate: self,
            background: true
        )
        
        print("MATCH POINT FLIC 2: Gestore inizializzato")
    }
    
    func cercaFlic2() {
        print("MATCH POINT FLIC 2: Avvio ricerca...")
        print("MATCH POINT FLIC 2: Nome attuale = \(nomePulsante)")
        
        FLICManager.shared()?.scanForButtons(
            stateChangeHandler: { event in
                print("MATCH POINT FLIC 2: Evento scansione \(event)")
            },
            completion: { button, error in
                if let error = error {
                    print("MATCH POINT FLIC 2: Errore \(error)")
                    return
                }
                
                guard let button = button else {
                    print("MATCH POINT FLIC 2: Nessun pulsante verificato")
                    return
                }
                
                print("MATCH POINT FLIC 2: Pulsante verificato!")
                self.nomePulsante = button.name ?? "Flic 2"
                self.flicPronto = button.isReady
                print("MATCH POINT FLIC 2: \(button.name ?? "Flic 2 senza nome")")
            }
        )
    }
    func button(_ button: FLICButton, didReceiveButtonClick queued: Bool, age: Int) {
        print("MATCH POINT FLIC 2: CLIC SINGOLO")

        DispatchQueue.main.async {
            self.flicPronto = button.isReady

            if !queued {
                MatchPointAudio.shared.suonaPunto()
                self.onPuntoA?()
            }
        }
    }
    
    func button(_ button: FLICButton,
                didReceiveButtonDoubleClick queued: Bool,
                age: Int) {

        print("MATCH POINT FLIC 2: DOPPIO CLIC")

        if !queued {
            DispatchQueue.main.async {
                MatchPointAudio.shared.suonaPunto()
                self.onPuntoB?()
            }
        }
    }
    
    func button(_ button: FLICButton,
                didReceiveButtonHold queued: Bool,
                age: Int) {

        print("MATCH POINT FLIC 2: PRESSIONE PROLUNGATA")

        if !queued {
            DispatchQueue.main.async {
                MatchPointAudio.shared.suonaAnnulla()
                self.onAnnulla?()
            }
        }
    }
    
}
