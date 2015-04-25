# #led-light-plugin configuration options
module.exports = {
  title: "Led light device config schemas"
  type: "object"
  properties:
    location:
      description: "Location of light device"
      type: "string"
    addr:
      description: "Address information of light device"
      type: "object"
    device:
      description: "Device Model (iwy-master | wifi370 | milight)"
      type: "string"
}
