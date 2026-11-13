
import SwiftUI

struct BluetoothView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var flic2 = Flic2Manager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Bluetooth MATCH POINT")
                    .font(.title2.bold())

              
                    .foregroundStyle(.secondary)
              
                VStack(alignment: .leading, spacing: 12) {
                    Label("Comandi · Modalità 1 pulsante", systemImage: "hand.tap")

                    Text("Clic singolo → Punto A")
                    Text("Doppio clic → Punto B")
                    Text("Pressione lunga → Annulla")
                    Divider()
                        .padding(.vertical, 6)

                    Label("Modalità 2 pulsanti", systemImage: "circle.grid.2x1")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text("Disponibile prossimamente: un Flic 2 per ciascuna squadra.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                
                Button {
                    Flic2Manager.shared.cercaFlic2()
                } label: {
                    Label("Aggiungi Flic 2", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

    
                
                VStack(alignment: .leading, spacing: 14) {

                    Label("Dispositivi associati", systemImage: "link")
                        .font(.headline)

                    HStack(spacing: 14) {

                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 5) {

                            Text(flic2.nomePulsante)
                                .font(.headline)

                            Label(
                                flic2.flicPronto
                                    ? "Pronto"
                                    : (flic2.flicInConnessione
                                        ? "In attesa di connessione"
                                        : "Non connesso"),
                                systemImage: flic2.flicPronto
                                    ? "checkmark.circle.fill"
                                    : (flic2.flicInConnessione
                                        ? "arrow.triangle.2.circlepath"
                                        : "xmark.circle.fill")
                            )
                            .font(.caption)
                            .foregroundStyle(
                                flic2.flicPronto
                                    ? Color.green
                                    : (flic2.flicInConnessione
                                        ? Color.orange
                                        : Color.red)
                            )
                        }

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                

                Spacer()
            }
            .padding()
            .navigationTitle("Dispositivi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}
