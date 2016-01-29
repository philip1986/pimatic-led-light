module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  # 'es6-promise' needs to be required at this point to initialize promises for the underlying base library
  es6Promise = require 'es6-promise'
  hue = require 'node-hue-api'
  BaseLedLight = require('./base')(env)


  class HueLight extends BaseLedLight

    constructor: (@config, lastState) ->
      @device = new hue.HueApi(
        @config.addr,
        @config.username,
        @config.timeout,
        @config.port,
      )

      @hueId = @config.hueId
      @hueStateCommand = if @config.isGroup then "setGroupLightState" else "setLightState"

      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)
      if @power then @turnOn() else @turnOff()

    _updateState: (attr) =>
      state = _.assign @getState(), attr
      super null, state

    turnOn: ->
      return new Promise( (resolve, reject) =>
        hueState = hue.lightState.create().on()
        @device[@hueStateCommand](@hueId, hueState).then( =>
          @_updateState power: true
          resolve()
        ).catch( (error) =>
          env.logger.error error.message ? error
          reject("" + error.message ? error)
        )
      )

    turnOff: ->
      return new Promise( (resolve, reject) =>
        hueState = hue.lightState.create().off()
        @device[@hueStateCommand](@hueId, hueState).then( =>
          @_updateState power: false
          resolve()
        ).catch( (error) =>
          env.logger.error error.message ? error
          reject("" + error.message ? error)
        )
      )

    setColor: (newColor) ->
      return new Promise( (resolve, reject) =>
        color = Color(newColor).rgb()
        hslColor = Color(newColor).hsl()
        hueState = hue.lightState.create().on().hsl(hslColor.h, hslColor.s, hslColor.l)
        @device[@hueStateCommand](@hueId, hueState).then(
          @_updateState
            mode: @COLOR_MODE
            color: color
            brightness: hslColor.l
            power: true
          resolve()
        ).catch( (error) =>
          env.logger.error error.message ? error
          reject("" + error.message ? error)
        )
      )

    setWhite: () ->
      return new Promise( (resolve, reject) =>
        hslColor = Color("#FFFFFF").hsl()
        hueState = hue.lightState.create().on().hsl(hslColor.h, hslColor.s, hslColor.l)
        @device[@hueStateCommand](@hueId, hueState).then(
          @_updateState
            mode: @WHITE_MODE
            power: true
          resolve()
        ).catch( (error) =>
          env.logger.error error.message ? error
          reject("" + error.message ? error)
        )
      )

    setBrightness: (newBrightness) ->
      return new Promise( (resolve, reject) =>
        # Maximum brightness for hue is 254 rather than 255
        # See also http://www.developers.meethue.com/content/maximum-brightness-254-or-255
        hueState = hue.lightState.create().on().bri(Math.round(newBrightness * 254 / 100))
        @device[@hueStateCommand](@hueId, hueState).then(
          rgbColor = @color
          unless rgbColor is ""
            hslColor = Color(rgbColor).hsl()
            hslColor.l = newBrightness
            rgbColor = Color(hslColor).rgb()
          @_updateState
            brightness: newBrightness
            power: true
            color: rgbColor
          resolve()
        ).catch( (error) =>
          env.logger.error error.message ? error
          reject("" + error.message ? error)
        )
      )

  return HueLight
