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
      supportedModes:
        description: "Supported light device modes (e.g.: WHITE, COLOR)"
        type: "array"
        required: false
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
      supportedModes:
        description: "Supported light device modes (e.g.: WHITE, COLOR)"
        type: "array"
        required: false
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
            supportedModes:
              description: "Supported light device modes (e.g.: WHITE, COLOR)"
              type: "array"
              required: false
  },
  Wifi370: {
    title: "LedLight"
    type: "object"
    properties:
      addr:
        description: "IP-Address of light device"
        type: "string"
      supportedModes:
        description: "Supported light device modes (e.g.: WHITE, COLOR)"
        type: "array"
        required: false
  },
  Blinkstick: {
    title: "BlinkStick"
    type: "object"
    properties:
      serial:
        description: "serial of Blinkstick"
        type: "string"
        default: ""
      supportedModes:
        description: "Supported light device modes (e.g.: WHITE, COLOR)"
        type: "array"
        required: false
  },
  DummyLedLight: {
    title: "DummyLedLight"
    type: "object"
    properties:
      supportedModes:
        description: "Supported light device modes (e.g.: WHITE, COLOR)"
        type: "array"
        required: false
  },
  HyperionLedLight: {
    title: "Hyperion"
    type: "object"
    properties:
      addr:
        description: "IP-Address of hyperion device"
        type: "string"
        default: "localhost"
      port:
        description: "Port of hyperion device"
        type: "string"
        default: "19444"
      supportedModes:
        description: "Supported light device modes (e.g.: WHITE, COLOR)"
        type: "array"
        required: false
  }
}
