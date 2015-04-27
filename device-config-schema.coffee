# #led-light-plugin configuration options
module.exports = {
  title: "Led light device config schemas"
  LedLight: {
    title: "LedLight"
    type: "object"
    properties:
      location:
        description: "Location of light device"
        type: "string"
      addr:
        description: "IP-Address of light device"
        type: "string"
      device:
        description: "Device Model (iwy-master | wifi370)"
        type: "string"
  }
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
  }
}
