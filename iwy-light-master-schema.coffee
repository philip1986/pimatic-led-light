# #my-plugin configuration options
# Declare your config option for your plugin here.
module.exports = {
  title: "iwy light master device config schemas"
  type: "object"
  properties:
    location:
      description: ""
      type: "string"
    addr:
      description: "IP-Address of light"
      type: "string"
}
