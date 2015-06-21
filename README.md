pimatic-led-light
=======================

A pimatic plugin for LED lights resp. LED-Stripes.
Currently supported:
  - [IWY Light Master] (http://iwy-light.de/gb/iwy-starter-sets/iwy-color-single-set-9w.html)
  - [WIFI370] (http://www.wifiledcontroller.com/#!wifi-370-controller/c1s9b)
  - [Milight] (http://www.milight.com)

## Configuration

### For IwyMasten and Wifi370

```
    {
      "id": "some_id",
      "name": "some_name",
      "class": "IwyMaster | Wifi370",
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

## Features

- switch on/off (UI and rules)
- dim light (UI)
- set color
  - by color picker (in UI)
  - by name (in rules e.g. red)
  - by hex (in rules e.g. #00FF00)
  - by teampature variable from weather plugin (in rules e.g. $weather.temperature)

