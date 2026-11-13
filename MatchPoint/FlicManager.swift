
import Foundation
import CoreBluetooth
import flic2lib

@Observable
final class FlicManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = FlicManager()
    var statoBluetooth = "In attesa..."
    var statoConnessione = "Nessun dispositivo collegato"
    var dispositiviRilevati: [String] = []
    
    var registroDiagnostica: [String] = []

    func aggiungiDiagnostica(_ messaggio: String) {
        registroDiagnostica.append(messaggio)

        print("MATCH POINT BLE: \(messaggio)")
    }

    var dispositivoSelezionato: String? {
        get {
            UserDefaults.standard.string(
                forKey: "dispositivoBluetoothSelezionato"
            )
        }
        set {
            UserDefaults.standard.set(
                newValue,
                forKey: "dispositivoBluetoothSelezionato"
            )
        }
    }

   
    func selezionaDispositivo(_ dispositivo: String) {
        dispositivoSelezionato = dispositivo

        let identificativo = dispositivo
            .components(separatedBy: " — ")
            .last ?? ""

        if let uuid = UUID(uuidString: identificativo) {
            UserDefaults.standard.set(
                uuid.uuidString,
                forKey: "flicUUIDPreferito"
            )
        }

        print("MATCH POINT: dispositivo selezionato \(dispositivo)")
    }


    private var central: CBCentralManager?
    private var perifericheTrovate: [UUID: CBPeripheral] = [:]
    private override init() {
        super.init()
    }
    
    
    func preparaBluetooth() {
        guard central == nil else {
            return
        }

        central = CBCentralManager(
            delegate: self,
            queue: nil
        )
    }

    
    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {
        if central.state == .poweredOn {
            statoBluetooth = "Bluetooth attivo"
            print("MATCH POINT: Bluetooth attivo")
            
            recuperaDispositivoPreferito()
            
            central.scanForPeripherals(
                withServices: nil,
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false
                ]
            )
        } else {statoBluetooth = "Bluetooth non disponibile"
            print("MATCH POINT: Bluetooth non disponibile")
        }
    }
    
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let nome = peripheral.name
        ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        ?? "Dispositivo senza nome"
        
        let identificativo = peripheral.identifier.uuidString
        perifericheTrovate[peripheral.identifier] = peripheral
        let descrizione = "\(nome) — \(identificativo)"
        
        if !dispositiviRilevati.contains(descrizione) {
            dispositiviRilevati.append(descrizione)
        }
        
        print("MATCH POINT: rilevato \(descrizione)")
    }
    
    func cercaDispositivi() {
        guard let central = central,
              central.state == .poweredOn else {
            statoBluetooth = "Bluetooth non disponibile"
            return
        }

        central.stopScan()
        dispositiviRilevati.removeAll()

        statoBluetooth = "Ricerca dispositivi in corso..."

        central.scanForPeripherals(
            withServices: nil,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )

        print("MATCH POINT: nuova ricerca Bluetooth avviata")
    }

 
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        central.stopScan()

        statoConnessione = "Collegato a \(peripheral.name ?? "dispositivo BLE")"

        peripheral.delegate = self

        print("MATCH POINT: connessione Bluetooth riuscita")
        print("MATCH POINT: ricerca servizi BLE...")

        peripheral.discoverServices(nil)
    }


    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        statoConnessione = "Dispositivo scollegato"

        if let error = error {
            print("MATCH POINT BLE: Disconnessione con errore")
            print("MATCH POINT BLE: \(error.localizedDescription)")
            print("MATCH POINT BLE: \(error)")
        } else {
            print("MATCH POINT BLE: Disconnessione senza errore")
        }
    }
    func collegaDispositivo(_ dispositivo: String) {
        guard let central = central,
              central.state == .poweredOn else {
            statoConnessione = "Bluetooth non disponibile"
            return
        }

        guard let uuidString = dispositivo
            .components(separatedBy: " — ")
            .last,
              let uuid = UUID(uuidString: uuidString),
              let peripheral = perifericheTrovate[uuid] else {
            statoConnessione = "Dispositivo non trovato"
            return
        }

        statoConnessione = "Connessione in corso..."

        central.connect(peripheral, options: nil)

        print("MATCH POINT: tentativo di connessione a \(dispositivo)")
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        let nome = peripheral.name ?? "dispositivo BLE"

        statoConnessione = "Connessione fallita: \(nome)"

        if let error = error {
            print("MATCH POINT: errore Bluetooth - \(error.localizedDescription)")
        } else {
            print("MATCH POINT: impossibile collegare \(nome)")
        }
    }

    func scollegaDispositivo(_ dispositivo: String) {
        guard let central = central,
              let uuidString = dispositivo.components(separatedBy: " — ").last,
              let uuid = UUID(uuidString: uuidString),
              let peripheral = perifericheTrovate[uuid] else {
            statoConnessione = "Dispositivo non trovato"
            return
        }

        central.cancelPeripheralConnection(peripheral)

        statoConnessione = "Disconnessione richiesta"

        print("MATCH POINT: disconnessione richiesta")
    }

    func recuperaDispositivoPreferito() {
        guard let central = central,
              central.state == .poweredOn else {
            return
        }

        guard let uuidString = UserDefaults.standard.string(
            forKey: "flicUUIDPreferito"
        ),
        let uuid = UUID(uuidString: uuidString) else {
            print("MATCH POINT: nessun dispositivo preferito")
            return
        }

        let dispositivi = central.retrievePeripherals(
            withIdentifiers: [uuid]
        )

        guard let peripheral = dispositivi.first else {
            print("MATCH POINT: dispositivo preferito non recuperabile")
            return
        }

        perifericheTrovate[uuid] = peripheral

        print("MATCH POINT: dispositivo preferito recuperato")
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        if let error = error {
            print("MATCH POINT: errore ricerca servizi: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else {
            print("MATCH POINT: nessun servizio BLE trovato")
            return
        }

        print("MATCH POINT: trovati \(services.count) servizi BLE")

        
        for service in services {
            print("MATCH POINT: servizio UUID \(service.uuid.uuidString)")
            aggiungiDiagnostica("Servizio: \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
        }

    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error = error {
            print("MATCH POINT: errore caratteristiche: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        print("MATCH POINT: caratteristiche del servizio \(service.uuid)")

        for characteristic in characteristics {
            print("UUID: \(characteristic.uuid)")
            print("Proprietà: \(characteristic.properties)")
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                print("MATCH POINT BLE: Attivazione notifiche su \(characteristic.uuid)")
            }
            aggiungiDiagnostica(
                "Caratteristica: \(characteristic.uuid.uuidString)"
            )

            aggiungiDiagnostica(
                "Proprietà: \(characteristic.properties)"
            )
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error = error {
            print("MATCH POINT BLE: Errore attivazione notifiche: \(error)")
        } else {
            print("MATCH POINT BLE: Notifiche attive: \(characteristic.isNotifying)")
            print("MATCH POINT BLE: UUID: \(characteristic.uuid)")
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error = error {
            print("MATCH POINT BLE: Errore ricezione: \(error)")
            return
        }

        guard let data = characteristic.value else {
            return
        }

        let hex = data.map {
            String(format: "%02X", $0)
        }.joined(separator: " ")

        print("MATCH POINT BLE: DATI RICEVUTI: \(hex)")
    }
}
