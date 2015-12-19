pimatic-led-light
=======================

A pimatic plugin for LED lights resp. LED-Stripes.
Currently supported:
  - [IWY Light Master] (http://iwy-light.de/gb/iwy-starter-sets/iwy-color-single-set-9w.html)
  - [WIFI370] (http://www.wifiledcontroller.com/#!wifi-370-controller/c1s9b)
  - [Milight] (http://www.milight.com)
  - [MilightRF24] (https://github.com/henryk/openmili)
  - [Blinkstick] (https://www.blinkstick.com)
  - [Hyperion] (https://github.com/tvdzwan/hyperion/wiki)

## Installation

To install the plugin on a Debian or Raspbian system libudev-dev must be installed.

    sudo apt-get install libudev-dev

## Configuration

### For IwyMaster

```
    {
      "id": "some_id",
      "name": "some_name",
      "class": "IwyMaster",
      "addr": "xxx.xxx.xxx.xxx"
    }
```

### For Wifi370

```
    {
      "id": "some_id",
      "name": "some_name",
      "class": "Wifi370",
      "addr": "xxx.xxx.xxx.xxx"
    }
```

### For Milight

```
    {
      "id": "some_id",
      "name": "some_name",
      "class": "Milight",
      "addr": "xxx.xxx.xxx.xxx",
      "zone": "Zone [0 - 4], 0 = switches all zones"
    }
```

### For MilightRF24

```
    {
      "id": 'some_id'
      "name": 'some_name'
      "class": 'MilightRF24'
      "port": '/dev/ttyUSB1'
      "zones": [
          {
            "addr": "5927",
            "zone": 0,
            "send": true,
            "receive": true
          },
          {
            "addr": "485D",
            "zone": 0,
            "send": true,
            "receive": true
          }
        ]
      }
```
You will get your addr when you just add the parameter MilightRF24Port to your config and switch to the debug output in pimatic and change some settings with your remote.

You need for example an arduino nano and connect it to an nrf24 using the standard SPI wiring.
Get the sketch from here https://github.com/henryk/openmili and change the CE and CSN pin to your wiring.

### For Blinkstick

```
    {
      "id": "some_id",
      "name": "some_name",
      "class": "Blinkstick",
      "serial": "xxx" // Only required if more than one Blinkstick is connected to the host.
    }
```

### For Hyperion

```
    {
      "id": "some_id",
      "name": "some_name",
      "class": "Wifi370",
      "addr": "xxx.xxx.xxx.xxx"
    }
```

## Features

- switch on/off (UI and rules)
- dim light (UI)
- set color
  - by color picker (in UI)
  - by name (in rules e.g. red)
  - by hex (in rules e.g. #00FF00)
  - by temperature variable from weather plugin (in rules e.g. $weather.temperature)

