
import SwiftUI

struct BluetoothView: View {
    @Environment(\.dismiss) private var dismiss

    private var bluetooth = FlicManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Bluetooth MATCH POINT")
                    .font(.title2.bold())

                Text(bluetooth.statoBluetooth)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                   
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(
                            bluetooth.statoConnessione.hasPrefix("Collegato a")
                                ? .green
                                : bluetooth.statoConnessione == "Connessione in corso..."
                                    ? .orange
                                    : .gray
                        )


                    Text(bluetooth.statoConnessione)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 12) {
                    Label("Flic 1", systemImage: "circle.dotted")

                    Text("Clic singolo → Punto A")
                    Text("Doppio clic → Punto B")
                    Text("Pressione lunga → Annulla")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                
                Button {
                    bluetooth.cercaDispositivi()
                } label: {
                    Label("Cerca dispositivi", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(bluetooth.statoBluetooth == "Bluetooth non disponibile")

                
                if let preferito = bluetooth.dispositivoSelezionato {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Dispositivo preferito", systemImage: "star.fill")
                            .font(.headline)

                        Text(preferito)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)

                        Label("Memorizzato, non necessariamente collegato",
                              systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text("Dispositivi rilevati")
                    .font(.headline)

                if bluetooth.dispositiviRilevati.isEmpty {
                    Text("Nessun dispositivo rilevato")
                        .foregroundStyle(.secondary)
                } else {
                   
              
                    List(bluetooth.dispositiviRilevati, id: \.self) { dispositivo in
                        VStack(alignment: .leading, spacing: 10) {

                            Button {
                                bluetooth.selezionaDispositivo(dispositivo)
                            } label: {
                                HStack {
                                    Label(dispositivo, systemImage: "bluetooth")
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if bluetooth.dispositivoSelezionato == dispositivo {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            HStack {
                                Button {
                                    bluetooth.collegaDispositivo(dispositivo)
                                } label: {
                                    Label("Collega", systemImage: "link")
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    bluetooth.scollegaDispositivo(dispositivo)
                                } label: {
                                    Label("Scollega", systemImage: "xmark.circle")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }


                }

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
