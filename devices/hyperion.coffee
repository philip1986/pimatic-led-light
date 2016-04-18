module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require('lodash')
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

    setMaxValue = (color, brightness) ->
      return parseInt((color / 255) * (brightness * 2.55), 10)

    # turning on sets color to white
    turnOn: ->
      @_updateState power: true
      if @mode
        color = Color(@color)
      else
        color = Color("#FFFFFF")
      @sendColor(color)
      Promise.resolve()

    # turning off means setting hyperion back to default state (usually capture)
    turnOff: ->
      @_updateState power: false
      this.connectToHyperion().then( (hyperion) =>
        hyperion.clear()
      )
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
      if @mode
        color = Color(@color)
      else
        color = Color("#FFFFFF")
      @setColor(color)
      Promise.resolve()

    sendColor: (newColor) =>
      color = newColor.rgbArray().map( (value) =>
        return setMaxValue(value, @brightness)
      )
      this.connectToHyperion().then( (hyperion) =>
        hyperion.setColor(color)
      ).catch( (error) =>
        env.logger.error("Caught error: " + error)
      ).done()

    connectToHyperion: (resolve) =>
      if @_connected
        return Promise.resolve(@hyperion)
      else
        @hyperion = new Hyperion(@config.addr, @config.port)
        @hyperion.on 'error', (error) =>
          env.logger.error("Error connecting to hyperion.")
          if (error?)
            env.logger.error(error)
          @_connected = false
        return eventToPromise(@hyperion, "connect").then( =>
          env.logger.info("Connected to hyperion!")
          @_connected = true
          return @hyperion
        )

  return HyperionLedLight
