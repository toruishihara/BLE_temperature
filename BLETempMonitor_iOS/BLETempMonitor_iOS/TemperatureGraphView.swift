//
//  TemperatureGraphView.swift
//  BLETempMonitor_iOS
//
//  Created by Toru Ishihara on 11/8/24.
//

import SwiftUI
import Charts

struct TemperatureGraphView: View {
    @StateObject private var viewModel: TemperatureViewModel

    init(bleManager: BLEManager) {
        _viewModel = StateObject(wrappedValue: TemperatureViewModel(bleManager: bleManager))
    }

    var body: some View {
        VStack {
            Text("Temperature Readings")
                .font(.title)
                .padding()
            
            /*
            List(viewModel.temperatureReadings) { reading in
                HStack {
                    Text(DateFormatter.timeWithSeconds.string(from: reading.time))
                    Spacer()
                    Text("\(reading.temperature, specifier: "%.2f") °C")
                }
            }
             */
            Chart(viewModel.temperatureReadings) { reading in
                LineMark(
                    x: .value("Time", reading.time),
                    y: .value("Temperature (°C)", reading.temperature)
                )
            }
            .chartYScale(domain: 0...40) // Set Y-axis range based on expected temperature
            .frame(height: 300)
            .padding()

        }
    }
}

extension DateFormatter {
    static let timeWithSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"  // Customize format as needed
        return formatter
    }()
}
