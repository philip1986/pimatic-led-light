pimatic-iwy-light-master
=======================

A pimatic plugin for [IWY Light Master] (http://iwy-light.de/gb/iwy-starter-sets/iwy-color-single-set-9w.html)

## Confuguration

```
    {
      "id": "some_id",
      "name": "some_name",
      "class": "IwyLightMaster",
      "location": "living room",
      "addr": "xxx.xxx.xxx.xxx"
    }

```

## Features

- switch on/off (UI and rules)
- dim light (UI and rules)
- set color
  - by color picker (in UI)
  - by name (in rules e.g. red)
  - by hex (in rules e.g. #00FF00)
  - by teampature variable from weather plugin (in rules e.g. $weather.temperature)

