//
//  ContentView.swift
//  BLETempMonitor_iOS
//
//  Created by Toru Ishihara on 11/7/24.
//

import SwiftUI
import CoreBluetooth
import Charts

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    
    // Lazy initialization for TemperatureViewModel using the same BLEManager instance
    private var viewModel: TemperatureViewModel {
        TemperatureViewModel(bleManager: bleManager)
    }
    
    var body: some View {
        VStack {
            //Text("Bluetooth Scanner")
            //    .font(.largeTitle)
            //    .padding()

            //List(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
            //    Text(peripheral.name ?? "Unknown Peripheral")
            //}
            Text("Time-Temperature Graph")
                .font(.title)
                .padding()

            TemperatureGraphView(bleManager: bleManager)

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
            
            Text("Temperature:")
            Text("\(bleManager.temperature, specifier: "%.2f") °C")
                .font(.largeTitle)
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
