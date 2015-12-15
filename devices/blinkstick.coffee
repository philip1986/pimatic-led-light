module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  BaseLedLight = require('./base')(env)


  class Blinkstick extends BaseLedLight

    constructor: (@config, lastState) ->
      nodeBlinkstick = require 'blinkstick'
      if @config.serial
        @device = new nodeBlinkstick.findBySerial(@config.serial)
      else
        @device = new nodeBlinkstick.findFirst()

      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)
      if @power then @turnOn() else @turnOff()

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    setMaxValue = (color, brightness) ->
      return (color / 255) * (brightness * 2.5)

    turnOn: ->
      @_updateState power: true
      if @mode
        color = Color(@color).rgb()
      else
        color =
          r: 255
          g: 255
          b: 255
      
      @device.setColor(setMaxValue(color.r, @brightness), setMaxValue(color.g, @brightness), setMaxValue(color.b, @brightness))
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      @device.turnOff()
      Promise.resolve()

    setColor: (newColor) ->
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      @device.setColor(setMaxValue(color.r, @brightness), setMaxValue(color.g, @brightness), setMaxValue(color.b, @brightness)) if @power
      Promise.resolve()

    setWhite: () ->
      @_updateState mode: @WHITE_MODE
      @device.setColor(setMaxValue(255, @brightness), setMaxValue(255, @brightness), setMaxValue(255, @brightness)) if @power
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
      @device.setColor(setMaxValue(color.r, newBrightness), setMaxValue(color.g, newBrightness), setMaxValue(color.b, newBrightness)) if @power
      Promise.resolve()
      
  return Blinkstick
