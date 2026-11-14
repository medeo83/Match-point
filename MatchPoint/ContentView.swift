
import SwiftUI
import WebKit
import AVFoundation

func configuraAudioMatchPoint() {
    do {
        try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.mixWithOthers]
        )
        
        try AVAudioSession.sharedInstance().setActive(true)

        print("MATCH POINT: Sessione audio configurata")
    } catch {
        print("MATCH POINT: Errore audio = \(error)")
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var comandoTest = 0
    @State private var numeroComando = 0
    @State private var mostraBluetooth = false
    @State private var partitaInCorso = false
    
    var body: some View {
        VStack(spacing: 0) {
            MatchPointWebView(
                comandoTest: comandoTest,
                numeroComando: numeroComando,
                partitaInCorso: $partitaInCorso
            )
            .ignoresSafeArea(edges: .horizontal)
            .onAppear {
                Flic2Manager.shared.avviaFlic2()
            }
            .sheet(isPresented: $mostraBluetooth) {
                BluetoothView()
            }
            
            if !partitaInCorso {
                HStack {
                    Button {
                        mostraBluetooth = true
                    } label: {
                        Label("Dispositivi Bluetooth", systemImage: "bluetooth")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 8)
                }
                
                .buttonStyle(.borderedProminent)
                .padding(8)
            }
        }
        .onChange(of: scenePhase) { _, nuovaFase in
            guard nuovaFase == .active, partitaInCorso else { return }

            guard let scena = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
            else { return }

            let richiesta = UIWindowScene.GeometryPreferences.iOS(
                interfaceOrientations: .landscape
            )

            scena.requestGeometryUpdate(richiesta) { errore in
                print("MATCH POINT: Errore ripristino rotazione = \(errore)")
            }
        }
    }
}


struct MatchPointWebView: UIViewRepresentable {

    var comandoTest: Int
    var numeroComando: Int
    @Binding var partitaInCorso: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(partitaInCorso: $partitaInCorso)
    }

    func makeUIView(context: Context) -> WKWebView {
        configuraAudioMatchPoint()
        _ = MatchPointAudio.shared
        let webView = WKWebView()
        webView.uiDelegate = context.coordinator
        webView.configuration.userContentController.add(
            context.coordinator,
            name: "matchPointOrientation"
        )
        
        webView.configuration.userContentController.add(
            context.coordinator,
            name: "matchPointAudio"
        )
        
        Flic2Manager.shared.onPuntoA = { [weak webView] in
            DispatchQueue.main.async {
                guard let webView = webView else { return }
                context.coordinator.puntoSquadraA(webView)
            }
        }

        Flic2Manager.shared.onPuntoB = { [weak webView] in
            DispatchQueue.main.async {
                guard let webView = webView else { return }
                context.coordinator.puntoSquadraB(webView)
            }
        }

        Flic2Manager.shared.onAnnulla = { [weak webView] in
            DispatchQueue.main.async {
                guard let webView = webView else { return }
                context.coordinator.annullaPunto(webView)
            }
        }
        
        if let url = Bundle.main.url(
            forResource: "index",
            withExtension: "html"
        ) {
            webView.loadFileURL(
                url,
                allowingReadAccessTo:
                    url.deletingLastPathComponent()
            )
        }

        return webView
    }


    
    func updateUIView(
        _ uiView: WKWebView,
        context: Context
    ) {
        guard numeroComando != context.coordinator.ultimoComando else {
            return
        }

        context.coordinator.ultimoComando = numeroComando

        switch comandoTest {
        case 1:
            context.coordinator.puntoSquadraA(uiView)
        case 2:
            context.coordinator.puntoSquadraB(uiView)
        case 3:
            context.coordinator.annullaPunto(uiView)
        default:
            break
        }
    }



    class Coordinator: NSObject, WKUIDelegate, WKScriptMessageHandler {
        var ultimoComando = 0
        var partitaInCorso: Binding<Bool>

        init(partitaInCorso: Binding<Bool>) {
            self.partitaInCorso = partitaInCorso
            super.init()
        }
        
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "matchPointAudio" {
                if let abilitato = message.body as? Bool {
                    MatchPointAudio.shared.suonoAbilitato = abilitato
                    print("MATCH POINT: Audio abilitato = \(abilitato)")
                }
                return
            }
            
            guard message.name == "matchPointOrientation",
                  let comando = message.body as? String else { return }

            DispatchQueue.main.async {
                self.partitaInCorso.wrappedValue = (comando == "landscape")
                UIApplication.shared.isIdleTimerDisabled = (comando == "landscape")
                
                let orientamento: UIInterfaceOrientationMask =
                    comando == "landscape" ? .landscape : .portrait

                guard let scena = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive })
                else { return }

                let richiesta = UIWindowScene.GeometryPreferences.iOS(
                    interfaceOrientations: orientamento
                )

                scena.requestGeometryUpdate(richiesta) { errore in
                    print("MATCH POINT: Errore rotazione = \(errore)")
                }
            }
        }
        // Comandi che useremo per il Bluetooth Flic

        func puntoSquadraA(_ webView: WKWebView) {
            webView.evaluateJavaScript("""
                (function() {
                    const audioOriginale = window.playSignal;
                    window.playSignal = function() {};

                    try {
                        score(0);
                    } finally {
                        window.playSignal = audioOriginale;
                    }
                })();
            """)
        }

        func puntoSquadraB(_ webView: WKWebView) {
            webView.evaluateJavaScript("""
                (function() {
                    const audioOriginale = window.playSignal;
                    window.playSignal = function() {};

                    try {
                        score(1);
                    } finally {
                        window.playSignal = audioOriginale;
                    }
                })();
            """)
        }

        func annullaPunto(_ webView: WKWebView) {
            webView.evaluateJavaScript("""
                (function() {
                    const audioOriginale = window.playSignal;
                    window.playSignal = function() {};

                    try {
                        undoPoint();
                    } finally {
                        window.playSignal = audioOriginale;
                    }
                })();
            """)
        }

        // Gestione delle conferme JavaScript

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(
                title: "MATCH POINT",
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(
                title: "Annulla",
                style: .cancel,
                handler: { _ in completionHandler(false) }
            ))

            alert.addAction(UIAlertAction(
                title: "Conferma",
                style: .default,
                handler: { _ in completionHandler(true) }
            ))

            guard let controller =
                webView.window?.rootViewController else {
                completionHandler(false)
                return
            }

            var presenter = controller
            while let presented = presenter.presentedViewController {
                presenter = presented
            }

            presenter.present(alert, animated: true)
        }
    }
}

#Preview {
    ContentView()
}
