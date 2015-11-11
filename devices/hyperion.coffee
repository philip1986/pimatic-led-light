module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  net = require 'net'
  BaseLedLight = require('./base')(env)

  ###
  ## implementation based on https://github.com/nfarina/homebridge-legacy-plugins/blob/master/accessories/Hyperion.js
  ###
  class Hyperion extends BaseLedLight

    constructor: (@config, lastState) ->
      @host = @config.host
      @port = @config.port
      @color = Color().hsv([0, 0, 0])
      @prevColor = Color().hsv([0, 0, 100])
      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)

      if @power then @turnOn() else @turnOff()

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    turnOn: ->
      @_updateState power: true
      @color.rgb(@prevColor.rgb())
      @sendColor()
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      @prevColor.rgb(@color.rgb())
      @color.value(0)
      @sendColor()
      @sendBlacklevel([0, 0, 0])
      Promise.resolve()

    setColor: (newColor) ->
      @color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      @sendColor()
      Promise.resolve()

    setWhite: ->
      @_updateState mode: @WHITE_MODE
      @setColor("#FFFFFF")
      # TODO: set device to white
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      @color.value(newBrightness)
      @sendColor()
      Promise.resolve()

    sendColor: (color) =>
      if color == null
        color = @color
      @sendHyperionCommand("color", color.rgbArray())

    sendBlacklevel: (blacklevel) =>
      @sendHyperionCommand("blacklevel", blacklevel)

    sendHyperionCommand: (command, params, priority) =>
      if priority == null
        priority = 100
      data = switch
        when command == "color" then {"command":"color", "priority":priority,"color":params}
        when command == "blacklevel" then {"command":"transform","transform":{"blacklevel":params}}
        else return
      client = new net.Socket()
      client.connect(@port, @host, ( => client.write(JSON.stringify(data) + "\n")) )

      client.on 'data', (data) =>
        env.logger.debug("Response: " + data.toString().trim())
        env.logger.debug("***** Color HSV:" + that.color.hsvArray() + "*****")
        env.logger.debug("***** Color RGB:" + that.color.rgbArray() + "*****")
        client.end()

  return Hyperion