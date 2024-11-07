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
    
    private var centralManager: CBCentralManager!
    
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
        }
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        print("Stopped scanning.")
    }
    
    // Called when a peripheral is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            print("Discovered: \(peripheral.name ?? "Unknown")")
        }
    }
}
