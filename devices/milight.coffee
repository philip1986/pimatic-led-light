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

      if lastState?.power?.value then @turnOn() else @turnOff

      @setBrightness lastState?.brightness?.value or 100
      @color = lastState?.color?.value or '#FFFFFF'

      if lastState?.mode?.value is @WHITE_MODE
        @setWhite()
      else
        @setColor @color

      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value

      super(initState)

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      console.log @getState(), state
      super null, state

    turnOn: ->
      @device.sendCommands(nodeMilight.commands.rgbw['on'](@zone))
      @_updateState power: true
      Promise.resolve()

    turnOff: ->
      @device.sendCommands(nodeMilight.commands.rgbw['off'](@zone))
      @_updateState power: false
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
        color: Color(newColor).rgb()

      Promise.resolve()

    setWhite: () ->
      @device.sendCommands(nodeMilight.commands.rgbw.whiteMode(@zone))

      @_updateState
        mode: @WHITE_MODE

      @setBrightness @brightness
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @device.sendCommands(nodeMilight.commands.rgbw.on(@zone), nodeMilight.commands.rgbw.brightness(newBrightness))

      @_updateState brightness: newBrightness
      Promise.resolve()

  return Milight
