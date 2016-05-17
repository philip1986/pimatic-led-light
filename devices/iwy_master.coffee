module.exports = (env) ->

  Promise = env.require 'bluebird'

  IwyMasterDriver = require 'iwy_master'
  BaseLedLight = require('./base')(env)

  class IwyMaster extends BaseLedLight
    constructor: (@config) ->
      if @config.class is 'Wifi370'
        deviceType = IwyMasterDriver.DEVICES.WIFI370
      else
        deviceType = IwyMasterDriver.DEVICES.IWY_MASTER

      @device = new IwyMasterDriver @config.addr, @config.port, deviceType
      @device.on 'error', (err) ->
        env.logger.warn 'light error:', err

      @_sync() # sync now
      super()

    _sync: ->
      @device.getState @_updateState.bind(@)

    turnOn: ->
      return Promise.resolve() if @power
      @device.switchOn @_updateState.bind(@)
      Promise.resolve()

    turnOff: ->
      return Promise.resolve() unless @power
      @device.switchOff @_updateState.bind(@)
      Promise.resolve()

    setColor: (newColor) ->
      unless @color is newColor
        red  = Number("0x#{newColor[1..2]}")
        green = Number("0x#{newColor[3..4]}")
        blue = Number("0x#{newColor[5..6]}")

        @device.setColor red, green, blue, @_updateState.bind(@)
      Promise.resolve()

    setWhite: ->
      unless @mode is 'WHITE'
        @device.setWhite @_updateState.bind(@)
      Promise.resolve()

    setBrightness: (newBrightness) ->
      unless @brightness is newBrightness
        @device.setBrightness newBrightness, @_updateState.bind(@)
      Promise.resolve()
