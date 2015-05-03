module.exports = (env) ->

  Promise = env.require 'bluebird'

  IwyMasterDriver = require 'iwy_master'
  BaseLedLight = require('./base')(env)

  class IwyMaster extends BaseLedLight
    constructor: (@config) ->
      @device = new IwyMasterDriver @config.addr, @config.device
      @device.on 'error', (err) ->
        env.logger.warn 'light error:', err

      # @_sync() # sync now

      super()

    _sync: ->
      @device.getState @_updateState.bind(@)

    turnOn: ->
      return Promise.resolve() if @power is 'on'
      @device.switchOn @_updateState.bind(@)
      Promise.resolve()

    turnOff: ->
      return Promise.resolve() if @power is 'off'
      @device.switchOff @_updateState.bind(@)
      Promise.resolve()

    setColor: (newColor) ->
      return Promise.resolve() if @color is newColor

      red  = Number("0x#{newColor[1..2]}")
      green = Number("0x#{newColor[3..4]}")
      blue = Number("0x#{newColor[5..6]}")

      @device.setColor red, green, blue, @_updateState.bind(@)
      Promise.resolve()

    setWhite: ->
      @device.setWhite @_updateState.bind(@)
      Promise.resolve()

    setBrightness: (newBrightness) ->
      return Promise.resolve() if @brightness is newBrightness
      @device.setBrightness newBrightness, @_updateState.bind(@)
      Promise.resolve()

