//
//  ContentView.swift
//  BLETempMonitor_iOS
//
//  Created by Toru Ishihara on 11/7/24.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()

    var body: some View {
        VStack {
            Text("Bluetooth Scanner")
                .font(.largeTitle)
                .padding()

            List(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                Text(peripheral.name ?? "Unknown Peripheral")
            }

            Button(action: {
                bleManager.isScanning ? bleManager.stopScanning() : bleManager.startScanning()
            }) {
                Text(bleManager.isScanning ? "Stop Scanning" : "Start Scanning")
                    .padding()
                    .background(bleManager.isScanning ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
