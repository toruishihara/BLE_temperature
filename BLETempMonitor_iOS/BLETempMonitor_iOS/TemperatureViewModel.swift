//
//  TemperatureViewModel.swift
//  BLETempMonitor_iOS
//
//  Created by Toru Ishihara on 11/8/24.
//

import SwiftUI
import Combine

struct TemperatureReading: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Float
}

class TemperatureViewModel: ObservableObject {
    @Published var temperatureReadings: [TemperatureReading] = []
    private var cancellables: Set<AnyCancellable> = []
    private let bleManager: BLEManager

    private var timer: AnyCancellable?
    
    init(bleManager: BLEManager) {
        self.bleManager = bleManager
        observeTemperatureUpdates()
    }
    
    // Observe temperature updates from BLEManager
    private func observeTemperatureUpdates() {
        bleManager.$temperature
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTemperature in
                self?.addTemperatureReading(newTemperature)
            }
            .store(in: &cancellables)
    }
    
    // Add a new temperature reading to the list with a timestamp
    private func addTemperatureReading(_ temperature: Float) {
        if (temperature > -99.0) { // Before connection temp = -100
            let reading = TemperatureReading(time: Date(), temperature: temperature)
            temperatureReadings.append(reading)
        }
        
        // Optional: Limit the number of readings to show a rolling graph (e.g., last 20 readings)
        //if temperatureReadings.count > 20 {
        //    temperatureReadings.removeFirst()
        //}
    }
}
