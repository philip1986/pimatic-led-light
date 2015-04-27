module.exports = (env) ->
  Promise = env.require 'bluebird'

  t = env.require('decl-api').types
  IwyMaster = require 'iwy_master'
  _ = require 'lodash'
  assert = require 'cassert'
  Color = require 'color'
  nodeMilight = require 'node-milight-promise'

  M = env.matcher

  color_schema = require './color_schema'


  class LedLightPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema.coffee")

      @framework.deviceManager.registerDeviceClass "LedLight",
        configDef: deviceConfigDef.LedLight
        createCallback: (config) -> return new LedLight(config)

      @framework.deviceManager.registerDeviceClass "Milight",
        configDef: deviceConfigDef.Milight
        createCallback: (config, lastState) -> return new Milight(config, lastState)

      # @framework.ruleManager.addActionProvider(new SwitchActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new ColorActionProvider(@framework))

      # wait till all plugins are loaded
      @framework.on "after init", =>
        # Check if the mobile-frontend was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-led-light/app/led-light.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-led-light/app/led-light.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-led-light/app/led-light.html"
          mobileFrontend.registerAssetFile 'js', "pimatic-led-light/app/vendor/spectrum.js"
          mobileFrontend.registerAssetFile 'css', "pimatic-led-light/app/vendor/spectrum.css"
        else
          env.logger.warn "your plugin could not find the mobile-frontend. No gui will be available"

  class LedLight extends env.devices.Device
    WHITE_MODE: 'WHITE'
    COLOR_MODE: 'COLOR'

    getTemplateName: -> "led-light"

    attributes:
      power:
        description: 'the current state of the light'
        type: t.boolean
        labels: ["on", "off"]
      color:
        description: 'color of the light'
        type: t.string
        unit: 'hex color'
      mode:
        description: 'mode of the light'
        type: t.boolean
        labels: ["color", "white"]
      brightness:
       description: 'brightness of the light'
       type: t.number
       unit: '%'

    template: "led-light"

    actions:
      getPower:
        description: "returns the current state of the light"
        returns:
          state:
            type: t.boolean
      getMode:
        description: "returns the color mode"
      turnOn:
        description: "turns the light on"
      turnOff:
        description: "turns the light off"
      toggle:
        description: "turns the light off or off"
      setWhite:
        description: "set the light to white mode"
      setColor:
        description: "set a light color"
        params:
          colorCode:
            type: t.string
      setBrightness:
        description: "set the light brightness"
        params:
          brightnessValue:
            type: t.number

    constructor: (@config) ->
      @name = @config.name
      @id = @config.id

      unless _.invert(IwyMaster.DEVICES)[@config.device]
        return env.logger.error 'unknown device'

      @device = new IwyMaster @config.addr, @config.device
      @device.on 'error', (err) ->
        env.logger.warn 'light error:', err

      @power = null
      @color = null
      @brightness = null
      @mode = null

      @_sync() # sync now

      super()

    _updateState: (err, state) ->
      env.logger.error err if err

      return unless state

      if state.mode is @WHITE_MODE
        hexColor = ''

      if state.mode is @COLOR_MODE
        hexColor = '#'
        hexColor += '0' if state.color.r < 16
        hexColor += state.color.r.toString(16)
        hexColor += '0' if state.color.g < 16
        hexColor += state.color.g.toString(16)
        hexColor += '0' if state.color.b < 16
        hexColor += state.color.b.toString(16)

      unless @power is state.power
        @power = state.power
        @emit 'power', if state.power then 'on' else 'off'

      unless @color is hexColor
        @color = hexColor
        @emit 'color', hexColor

      unless @brightness is state.brightness
        @brightness = state.brightness
        @emit 'brightness', state.brightness

    _sync: ->
      @device.getState @_updateState.bind(@)

    getPower: -> Promise.resolve @power
    getColor: -> Promise.resolve @color
    getMode: -> Promise.resolve @mode
    getBrightness: -> Promise.resolve @brightness

    turnOn: ->
      return Promise.resolve() if @power is 'on'
      @device.switchOn @_updateState.bind(@)
      Promise.resolve()

    turnOff: ->
      return Promise.resolve() if @power is 'off'
      @device.switchOff @_updateState.bind(@)
      Promise.resolve()

    toggle: ->
      if @power is 'on'
        @device.switchOn @_updateState.bind(@)
      else
        @device.switchOn @_updateState.bind(@)

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


  class Milight extends env.devices.Device

    getTemplateName: -> "led-light"

    attributes:
      power:
        description: 'the current state of the light'
        type: t.boolean
        labels: ["on", "off"]
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

    template: "led-light"

    actions:
      getPower:
        description: "returns the current state of the light"
        returns:
          state:
            type: t.boolean
      getMode:
        description: "returns the color mode"
      turnOn:
        description: "turns the light on"
      turnOff:
        description: "turns the light off"
      setWhite:
        description: "set the light to white mode"
      setColor:
        description: "set a light color"
        params:
          colorCode:
            type: t.string
      setBrightness:
        description: "set the light brightness"
        params:
          brightnessValue:
            type: t.number

    constructor: (@config, lastState) ->
      @name = @config.name
      @id = @config.id

      @device = new nodeMilight.MilightController({
        ip: @config.addr,
      })
      @zone = @config.zone

      console.log(lastState)

      @_setPowerTo lastState?.power?.value or false
      @setBrightness lastState?.brightness?.value or 100
      @color = lastState?.color?.value or '#FFFFFF'
      @mode = lastState?.mode?.value or false
      if @mode is false
        @setWhite
      else
        @setColor @color
      super()

    getPower: -> Promise.resolve @power
    getColor: -> Promise.resolve @color
    getMode: -> Promise.resolve @mode
    getBrightness: -> Promise.resolve @brightness

    _setAttribute: (attributeName, value) ->
      console.log("_setAttribute ---", attributeName, value)
      if @[attributeName] isnt value
        @[attributeName] = value
        @emit(attributeName, value)

    turnOn: -> @_setPowerTo true
    turnOff: -> @_setPowerTo false
    _setPowerTo: (power) ->
      if @power isnt power
        @power = power
        @emit('power', power)
        @emit 'power', if power then 'on' else 'off'

      console.log("_setPowerTo ---", power)
      @device.sendCommands(nodeMilight.commands.rgbw[if power then 'on' else 'off'](@zone))

    setColor: (newColor) ->
      r = Number("0x#{newColor[1..2]}")
      g = Number("0x#{newColor[3..4]}")
      b = Number("0x#{newColor[5..6]}")
      @_setAttribute('mode', true)
      @_setAttribute('color', newColor)
      @device.sendCommands(nodeMilight.commands.rgbw.on(@zone), nodeMilight.commands.rgbw.rgb255(r, g, b))

    setWhite: () ->
      @_setAttribute('mode', false)
      @device.sendCommands(nodeMilight.commands.rgbw.whiteMode(@zone))
      @setBrightness @brightness

    setBrightness: (newBrightness) ->
      @_setAttribute('brightness', newBrightness)
      @device.sendCommands(nodeMilight.commands.rgbw.on(@zone), nodeMilight.commands.rgbw.brightness(newBrightness))


  class ColorActionHandler extends env.actions.ActionHandler
    constructor: (@provider, @device, @color, @variable) ->
      @_variableManager = null

      if @variable
        @_variableManager = @provider.framework.variableManager

    executeAction: (simulate) =>
      getColor = (callback) =>
        if @variable
          @_variableManager.evaluateStringExpression([@variable])
            .then (temperature) =>
              temperatureColor = new Color()
              hue = 30 + 240 * (30 - temperature) / 60;
              temperatureColor.hsl(hue, 70, 50)

              hexColor = '#'
              hexColor += temperatureColor.rgb().r.toString(16)
              hexColor += temperatureColor.rgb().g.toString(16)
              hexColor += temperatureColor.rgb().b.toString(16)

              callback hexColor
        else
          callback @color

      getColor (color) =>
        if simulate
          return Promise.resolve(__("would log set color #{color}"))
        else
          @device.setColor color
          return Promise.resolve(__("set color #{color}"))

  class ColorActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->

    parseAction: (input, context) =>
      iwyDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("setColor")
      ).value()

      hadPrefix = false

      # Try to match the input string with: set ->
      m = M(input, context).match(['set '])

      device = null
      color = null
      match = null
      variable = null

      # device name -> color
      m.matchDevice iwyDevices, (m, d) ->
        # Already had a match with another device?
        if device? and device.id isnt d.id
          context?.addError(""""#{input.trim()}" is ambiguous.""")
          return

        device = d

        m.match [' to '], (m) ->
          m.or [
            # rgb hex like #00FF00
            (m) ->
              # TODO: forward pattern to UI
              m.match [/(#[a-fA-F\d]{6})(.*)/], (m, s) ->
                color = s.trim()
                match = m.getFullMatch()

            # color name like red
            (m) -> m.match _.keys(color_schema), (m, s) ->
                color = color_schema[s]
                match = m.getFullMatch()

            # color by temprature from variable like $weather.temperature = 30
            (m) ->
              m.match ['temperature based color by variable '], (m) ->
                m.matchVariable (m, s) ->
                  variable = s
                  match = m.getFullMatch()
          ]

      if match?
        assert device?
        # either variable or color should be set
        assert variable? ^ color?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new ColorActionHandler(@, device, color, variable)
        }
      else
        return null

  return new LedLightPlugin()
