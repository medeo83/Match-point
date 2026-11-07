
import SwiftUI
import WebKit
import fliclib

struct ContentView: View {
    @State private var comandoTest = 0
    @State private var numeroComando = 0
    @State private var mostraBluetooth = false
    var body: some View {
        VStack(spacing: 0) {
            MatchPointWebView(
                comandoTest: comandoTest,
                numeroComando: numeroComando
            )
            .ignoresSafeArea(edges: .horizontal)
            .onAppear {
                FlicManager.shared.preparaBluetooth()
            }
            .sheet(isPresented: $mostraBluetooth) {
                BluetoothView()
            }
            HStack {
                
                Button {
                    mostraBluetooth = true
                } label: {
                    Label("Dispositivi Bluetooth", systemImage: "bluetooth")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 8)

                Button("Punto A") {
                    comandoTest = 1
                    numeroComando += 1
                }

                Button("Punto B") {
                    comandoTest = 2
                    numeroComando += 1
                }

                Button("Annulla") {
                    comandoTest = 3
                    numeroComando += 1
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(8)

        }
    }
}


struct MatchPointWebView: UIViewRepresentable {

    var comandoTest: Int
    var numeroComando: Int
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()

        webView.uiDelegate = context.coordinator

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



    class Coordinator: NSObject, WKUIDelegate {
        var ultimoComando = 0
        // Comandi che useremo per il Bluetooth Flic

        func puntoSquadraA(_ webView: WKWebView) {
            webView.evaluateJavaScript("score(0);")
        }

        func puntoSquadraB(_ webView: WKWebView) {
            webView.evaluateJavaScript("score(1);")
        }

        func annullaPunto(_ webView: WKWebView) {
            webView.evaluateJavaScript("undoPoint();")
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
