module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  nodeMilight = require 'node-milight-promise'
  BaseLedLight = require('./base')(env)


  class Milight extends BaseLedLight

    constructor: (@config, lastState) ->
      @device = new nodeMilight.MilightController
        ip: @config.addr

      @zone = @config.zone

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
      @device.sendCommands(nodeMilight.commands.rgbw.on(@zone))
      if @mode
        color = Color(@color).rgb()
        @device.sendCommands(nodeMilight.commands.rgbw.rgb255(color.r, color.g, color.b))
      else
        @device.sendCommands(nodeMilight.commands.rgbw.whiteMode(@zone))
        @device.sendCommands(nodeMilight.commands.rgbw.brightness(@brightness))
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      @device.sendCommands(nodeMilight.commands.rgbw.off(@zone))
      Promise.resolve()

    setColor: (newColor) ->
      r = Number("0x#{newColor[1..2]}")
      g = Number("0x#{newColor[3..4]}")
      b = Number("0x#{newColor[5..6]}")
      if r == 255 && g == 255 && b == 255
        return @setWhite()

      @device.sendCommands(nodeMilight.commands.rgbw.on(@zone), nodeMilight.commands.rgbw.rgb255(r, g, b))

      @_updateState
        mode: @COLOR_MODE
        color: color
      @device.sendCommands(
        nodeMilight.commands.rgbw.on(@zone),
        nodeMilight.commands.rgbw.rgb255(color.r, color.g, color.b)
      ) if @power
      Promise.resolve()

    setWhite: () ->
      @device.sendCommands(nodeMilight.commands.rgbw.whiteMode(@zone))

      @_updateState
        mode: @WHITE_MODE

      @setBrightness @brightnessb
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      @device.sendCommands(
        nodeMilight.commands.rgbw.on(@zone),
        nodeMilight.commands.rgbw.brightness(@brightness)
      ) if @power

      Promise.resolve()

  return Milight
