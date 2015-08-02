# #pimatic-solarview configuration options
module.exports = {
  title: "Plugin config options"
  type: "object"
  properties:
    MilightRF24Port:
      description: "Port of arduino with openmili sketch"
      type: "string"
      default: ""
}