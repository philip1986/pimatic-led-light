module.exports = (env) ->
  Promise = env.require 'bluebird'

  t = env.require('decl-api').types
  assert = require 'cassert'
  Color = require 'color'


  class BaseLedLight extends env.devices.Device
    WHITE_MODE: 'WHITE'
    COLOR_MODE: 'COLOR'

    getTemplateName: -> 'led-light'

    attributes:
      power:
        description: 'the current state of the light'
        type: t.boolean
        labels: ['on', 'off']
      color:
        description: 'color of the light'
        type: t.string
        unit: 'hex color'
      mode:
        description: 'mode of the light'
        type: t.boolean
        labels: ['color', 'white']
      brightness:
       description: 'brightness of the light'
       type: t.number
       unit: '%'

    template: 'led-light'

    actions:
      getPower:
        description: 'returns the current state of the light'
        returns:
          state:
            type: t.boolean
      getMode:
        description: 'returns the light mode'
      turnOn:
        description: 'turns the light on'
      turnOff:
        description: 'turns the light off'
      toggle:
        description: 'turns the light off or off'
      setWhite:
        description: 'set the light to white mode'
      setColor:
        description: 'set a light color'
        params:
          colorCode:
            type: t.string
      setBrightness:
        description: 'set the light brightness'
        params:
          brightnessValue:
            type: t.number

    constructor: (initState) ->
      unless @device
        throw new Error 'no device initialized'

      @name = @config.name
      @id = @config.id

      @power = initState?.power or null
      @color = initState?.color or null
      @brightness = initState?.brightness or null
      @mode = initState?.mode or null

      super()

    _updateState: (err, state) ->
      env.logger.error err if err

      return unless state

      if state.mode is @WHITE_MODE
        hexColor = ''
        @mode = @WHITE_MODE

      if state.mode is @COLOR_MODE

        hexColor = '#'
        hexColor += '0' if state.color.r < 16
        hexColor += state.color.r.toString(16)
        hexColor += '0' if state.color.g < 16
        hexColor += state.color.g.toString(16)
        hexColor += '0' if state.color.b < 16
        hexColor += state.color.b.toString(16)

        @mode = @COLOR_MODE

      unless @power is state.power
        @power = state.power
        @emit 'power', if state.power then 'on' else 'off'

      unless @color is hexColor
        @color = hexColor
        @emit 'color', hexColor

      unless @brightness is state.brightness
        @brightness = state.brightness
        @emit 'brightness', state.brightness

    getPower: -> Promise.resolve @power
    getColor: -> Promise.resolve @color
    getMode: -> Promise.resolve @mode
    getBrightness: -> Promise.resolve @brightness

    getState: ->
      mode: @mode
      color: if @color then Color(@color).rgb() else null
      power: @power
      brightness: @brightness

    turnOn: -> throw new Error "Function 'turnOn' is not implemented!"
    turnOff: -> throw new Error "Function 'turnOff' is not implemented!"
    setColor: -> throw new Error "Function 'setColor' is not implemented!"
    setWhite: -> throw new Error "Function 'setWhite' is not implemented!"
    setBrightness: -> throw new Error "Function 'setBrightness' is not implemented!"

    toggle: ->
      if @power is 'on' then @turnOn() else @turnOff()
      Promise.resolve()

  return BaseLedLight
