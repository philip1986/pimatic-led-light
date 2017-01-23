module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require('lodash')
  Color = require 'color'

  YeelightDriver = require 'node-yeelight'
  BaseLedLight = require('./base')(env)

  class Yeelight extends BaseLedLight
    constructor: (@config, lastState) ->

      @device = new YeelightDriver()
      env.logger.debug 'init'

      @device.once 'ready', =>
        env.logger.debug 'ready'
        @device.discover()

      @device.on 'deviceadded', (newDevice) =>
        env.logger.debug 'device found', newDevice
        if newDevice.host is @config.addr
          env.logger.debug 'device matched'
          @light = newDevice
          @device.connect @light
          @device.removeAllListeners 'deviceadded'
          if @device.power is 'off'
            if @power then @turnOn() else @turnOff()
          else
            @_updateState brightness: parseInt @device.brightness
            @turnOn()

      @device.on 'error', (err) ->
        env.logger.error 'light error:', err

      @device.listen()

      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)

    destroy: () ->
      super()

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    turnOn: ->
      @_updateState power: true
      @device.setPower @light, true, 500
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      @device.setPower @light, false, 500
      Promise.resolve()

    setColor: (newColor) ->
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      @device.setRGB @light, parseInt("0x#{newColor[1..6]}"), 100
      Promise.resolve()

    setWhite: ->
      @_updateState
        mode: @WHITE_MODE
      @device.setRGB @light, parseInt("0xFFFFFF"), 100
      Promise.resolve()

    setBrightness: (newBrightness) ->
      if newBrightness is 0
        result = @turnOff()
      else
        result = @turnOn()

      result.then () =>
        @device.setBrightness @light, newBrightness, 0
        @_updateState brightness: newBrightness
