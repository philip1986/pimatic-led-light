module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  nodeBlinkstick = require 'blinkstick'
  BaseLedLight = require('./base')(env)


  class Blinkstick extends BaseLedLight

    constructor: (@config, lastState) ->
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

    turnOn: ->
      @_updateState power: true
      if @mode
        color = Color(@color).rgb()
        @device.setColor(color.r, color.g, color.b)
      else
        @device.setColor("#ffffff")
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
      @device.setColor(color.r, color.g, color.b) if @power
      Promise.resolve()

    setWhite: () ->
      @_updateState mode: @WHITE_MODE
      @device.setColor("#ffffff") if @power
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      @device.setColor(@brightness) if @power

      Promise.resolve()
      
  return Blinkstick