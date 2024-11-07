//
//  BLEManager.swift
//  BLETempMonitor_iOS
//
//  Created by Toru Ishihara on 11/7/24.
//

import SwiftUI
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isScanning = false
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var temperatureValue: Float = 0.0  // To store the temperature value

    private var centralManager: CBCentralManager!
    private var temperatureCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // This is called when the central manager's state is updated
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            print("Bluetooth is not available.")
        }
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            isScanning = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Started scanning for peripherals...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.connectTask()
            }
        }
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        print("Stopped scanning.")
    }
    
    func connectTask() {
        print("Task executed after 5 seconds.")
        stopScanning()
        for peripheral in discoveredPeripherals {
            if let name = peripheral.name {
                print("On List device: \(name)")
                if (name == "ESP32_BLE_GATT") {
                    print("target device")
                    connectToPeripheral(peripheral)
                }
            } else {
                print("device with no name")
            }
        }
    }

    
    // Called when a peripheral is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            print("Discovered: \(peripheral.name ?? "Unknown")")
        }
    }
    
    // Connect to a selected peripheral
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        peripheral.delegate = self
    }
    
    // Called when a connection is successfully made
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        print("Connected to \(peripheral.name ?? "Unknown")")
        
        // Discover services once connected
        peripheral.discoverServices(nil)
    }
    
    // Called if the connection fails
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "No error information")")
    }
    
    // Called when the peripheral disconnects
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown")")
        connectedPeripheral = nil
    }
    
    // Called when services are discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                print("Service found: \(service.uuid)")
                
                // Discover characteristics for each service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // Called when characteristics are discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Characteristic found: \(characteristic.uuid)")
                
                // Check for the temperature characteristic (UUID: 2A1C)
                if characteristic.uuid == CBUUID(string: "2A1C") {
                    temperatureCharacteristic = characteristic
                    // Read the characteristic value
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    // Called when a characteristic's value is updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic value: \(error.localizedDescription)")
            return
        }
        
        if characteristic.uuid == CBUUID(string: "2A1C"), let data = characteristic.value {
            // Decode the temperature data from the characteristic's value
            temperatureValue = decodeTemperatureData(data)
            print("Temperature: \(temperatureValue) °C")
        }
    }
    
    // Helper function to decode temperature data from characteristic value
    private func decodeTemperatureData(_ data: Data) -> Float {
        // Assuming the data is in IEEE-11073 32-bit floating point format
        var temperature: Float = 0.0
        if data.count >= 4 {
            temperature = data.withUnsafeBytes { $0.load(as: Float.self) }
        }
        return temperature
    }

}
