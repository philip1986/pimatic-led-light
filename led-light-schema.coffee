# #pimatic-solarview configuration options
module.exports = {
  title: "Plugin config options"
  type: "object"
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
}
