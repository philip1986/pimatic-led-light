module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  net = require 'net'
  eventToPromise = require 'event-to-promise'
  BaseLedLight = require('./base')(env)
  Hyperion = require 'hyperion-client'
  ###
  ## implementation based on https://github.com/danimal4326/homebridge-hyperion
  ###
  class HyperionLedLight extends BaseLedLight

    _connected: false

    constructor: (@config, lastState) ->
      @device = @
      @_dimlevel = lastState?.dimlevel?.value or 0

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
      env.logger.debug("turnOn not implemented yet")
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      env.logger.debug("turnOff not implemented yet")
      Promise.resolve()

    setColor: (newColor) ->
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      @sendColor(Color(newColor))
      Promise.resolve()

    setWhite: ->
      @_updateState mode: @WHITE_MODE
      @setColor("#FFFFFF")
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      env.logger.debug("setBrightness not implemented yet")
      Promise.resolve()

    sendColor: (newColor) =>
      this.connectToHyperion().then( (hyperion) =>
        hyperion.setColor(newColor.rgbArray(), (error, result) =>
          if typeof err != 'undefined'
            env.logger.error("Error setting color " + newColor + ". Error: " + error)
          else
            env.logger.debug("Color set to " + newColor)
        )
      ).catch( (error) =>
        throw new Error("Caught error: " + error)
      ).done()

    connectToHyperion: (resolve) =>
      if @_connected
        return Promise.resolve(@hyperion)
      else
        @hyperion = new Hyperion(@config.addr, @config.port)
        @hyperion.on 'error', (error) =>
          env.logger.console.error("Error connecting to hyperion:" + error)
          @_connected = false
        return eventToPromise(@hyperion, "connect").then( =>
          env.logger.info("Connected to hyperion!")
          @_connected = true
          return @hyperion
        )

  return HyperionLedLight
