# BLE_temperature
Bluetooth Low Energy temperature sensor Firmware and mobile app
| Supported Targets | Espressif ESP32-WROOM-32D |

# Room temperature GATT Server Example

### PIN connection ESP32-WROOM-32D and DHT22
```
ESP32 GROUND -- DHT22 GROUND
ESP32 VCC    -- DHT22 VCC
ESP32 P17    -- DHT22 S
```

### Import component
Clone https://github.com/UncleRus/esp-idf-lib.git
make subdir of components and make symbolik link
```
cd esp32_fw
mkdir components
cd components
ln -s ~/esp/esp-idf-lib/components/dht dht
ln -s ~/esp/esp-idf-lib/components/esp_idf_lib_helpers esp_idf_lib_helpers
```

### For build
```
cd esp32_fw
idf.py set-target esp32
idf.py build
```

### For flash on macOS terminal
```
idf.py -p /dev/cu.SLAB_USBtoUART flash
```

### For running on macOS terminal
```
idf.py -p /dev/cu.SLAB_USBtoUART monitor
```

End monitor by Ctrl + ]


### Measuring with Chart
![Measuring temp 0](images/temp2.jpg)
![Measuring temp 1](images/temp3.jpg)

Sensor is on the ice back. Temperature is down slowly. 
