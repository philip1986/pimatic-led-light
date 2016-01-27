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
      @_updateState power: true
      hueState = hue.lightState.create().on()
      @device[@hueStateCommand](@hueId, hueState)
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      hueState = hue.lightState.create().off()
      @device[@hueStateCommand](@hueId, hueState)
      Promise.resolve()
    
    setColor: (newColor) ->
      color = Color(newColor).rgb()
      hslColor = Color(newColor).hsl()
      if color.r == 255 && color.g == 255 && color.b == 255
        return @setWhite()
      else
        @_updateState
            mode: @COLOR_MODE
            color: color
            power: true
        hueState = hue.lightState.create().on().hsl(hslColor.h, hslColor.s, hslColor.l)
        @device[@hueStateCommand](@hueId, hueState)
      Promise.resolve()
    
    setWhite: () ->
      @_updateState
          mode: @WHITE_MODE
          power: true
      hslColor = Color("#FFFFFF").hsl()
      hueState = hue.lightState.create().on().hsl(hslColor.h, hslColor.s, hslColor.l)
      @device[@hueStateCommand](@hueId, hueState)
      Promise.resolve()

    setBrightness: (newBrightness) ->
      # Maximum brightness for hue is 254 rather than 255
      # See also http://www.developers.meethue.com/content/maximum-brightness-254-or-255
      @_updateState
          brightness: newBrightness
          power: true
      hueState = hue.lightState.create().on().bri(Math.round(newBrightness * 254 / 100))
      @device[@hueStateCommand](@hueId, hueState)
      Promise.resolve()

  return HueLight
