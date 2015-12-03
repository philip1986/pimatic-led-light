module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  net = require 'net'
  BaseLedLight = require('./base')(env)

  ###
  ## implementation based on https://github.com/danimal4326/homebridge-hyperion
  ###
  class Hyperion extends BaseLedLight

    constructor: (@config) ->
      @host = @config.host
      @port = @config.port
      @color = Color().hsv([0, 0, 0])
      @prevColor = Color().hsv([0, 0, 100])

      super()

      if @power then @turnOn() else @turnOff()

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    turnOn: ->
      @_updateState power: true
      if @mode
        color = Color(@color).rgb()
      else
        color = Color("#FFFFFF")
      @sendColor(color)
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      @setColor("#000000")
      @sendBlacklevel([0, 0, 0])
      Promise.resolve()

    setColor: (newColor) ->
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      @sendColor(color)
      Promise.resolve()

    setWhite: ->
      @_updateState mode: @WHITE_MODE
      @setColor("#FFFFFF")
      # TODO: set device to white
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      if @mode
        color = Color(@color).rgb()
      else
        color =
          r: 255
          g: 255
          b: 255
      # TODO: adjust brightness
      Promise.resolve()

    sendColor: (newColor) =>
      env.logger.debug("sending color: " + newColor.constructor.name)
      if newColor == null
        newColor = @color
      @sendHyperionCommand("color", [newColor.r, newColor.g, newColor.b])

    sendBlacklevel: (blacklevel) =>
      @sendHyperionCommand("blacklevel", blacklevel)

    sendHyperionCommand: (command, params, priority) =>
      if priority == null
        priority = 100
      data = null
      if command == "color"
        data = {"command":"color", "priority":priority,"color":params}
      else if command == "blacklevel"
        data = {"command":"transform","transform":{"blacklevel":params}}

      if data != null
        client = new net.Socket()
        env.logger.info("data = " + JSON.stringify(data))
        client.connect(@port, @host, ( => client.write(JSON.stringify(data) + "\n")) )

        client.on 'data', (data) =>
          env.logger.debug("Response: " + data.toString().trim())
          client.end()

        client.on 'error', (err) =>
          env.logger.debug("Error connecting to hyperion device. Error code was: " + err.code)
          client.end()
  return Hyperion
