# #led-light-plugin configuration options
module.exports = {
  title: "Led light device config schemas"
  LedLight: {
    title: "LedLight"
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
  }
}
