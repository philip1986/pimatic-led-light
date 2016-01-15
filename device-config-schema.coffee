# #led-light-plugin configuration options
module.exports = {
  title: "Led light device config schemas"
  IwyMaster: {
    title: "IwyMaster LedLight"
    type: "object"
    properties:
      addr:
        description: "IP-Address of light device"
        type: "string"
  },
  Milight: {
    title: "Milight"
    type: "object"
    properties:
      addr:
        description: "IP-Address of light device"
        type: "string"
      zone:
        description: "Zone [0 - 4], 0 = switches all zones"
        type: "number"
  },
  MilightRF24: {
    title: "Milight"
    type: "object"
    properties:
      zones:
        description: "The switch protocols to use."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            addr:
              description: "Address of light device"
              type: "string"
            port:
              description: "USB port where the gateway is attached"
              type: "string"
            zone:
              description: "Zone [0 - 4], 0 = switches all zones"
              type: "number"
            send:
              description: "Send commands using this address and zone"
              type: "boolean"
              default: true
            receive:
              description: "Respond on received commands using this address and zone"
              type: "boolean"
              default: true
  },
  Wifi370: {
    title: "LedLight"
    type: "object"
    properties:
      addr:
        description: "IP-Address of light device"
        type: "string"
  },
  Blinkstick: {
    title: "BlinkStick"
    type: "object"
    properties:
      serial:
        description: "serial of Blinkstick"
        type: "string"
        default: ""
  },
  DummyLedLight: {
    title: "DummyLedLight"
    type: "object"
    properties: {}
  },
  HyperionLedLight: {
    title: "Hyperion",
    type: "object"
    properties:
      addr:
        description: "IP-Address of hyperion device"
        type: "string"
        default: "localhost"
      port:
        description: "Port of hyperion device"
        type: "string",
        default: "19444"
  },
  Hue: {
    title: "Hue Light",
    type: "object"
    properties:
      addr:
        description: "IP-Address of hue bridge"
        type: "string"
      username:
        description: "Username registered (white-listed) on the bridge for PUT access"
        type: "string"
      hueId:
        description: "The light or group id to be controlled"
        type: "number"
      isGroup:
        description: "If set to true the id property is group id. It is a light id, otherwise."
        type: "boolean"
        default: false
      port:
        description: "Port of hue bridge (provided for testing purposes)"
        type: "number",
        default: 80
      timeout:
        description: "Timeout in ms for a pending bridge request to complete"
        type: "number"
        default: 10000
  }
}
