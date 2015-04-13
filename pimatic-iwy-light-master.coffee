module.exports = (env) ->
  Promise = env.require 'bluebird'

  t = env.require('decl-api').types
  Iwy_master = require 'iwy_master'
  _ = require 'lodash'
  assert = require 'cassert'
  Color = require 'color'

  M = env.matcher

  color_schema = require './color_schema'

  class IwyLightMasterPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./iwy-light-master-schema")

      @framework.deviceManager.registerDeviceClass "IwyLightMaster",
        configDef: deviceConfigDef
        createCallback: (config) -> return new IwyLightMaster(config)

      @framework.ruleManager.addActionProvider(new SwitchActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new ColorActionProvider(@framework))

      # wait till all plugins are loaded
      @framework.on "after init", =>
        # Check if the mobile-frontent was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-iwy-light-master/app/iwy-light-master.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-iwy-light-master/app/iwy-light-master.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-iwy-light-master/app/iwy-light-master.html"
          mobileFrontend.registerAssetFile 'js', "pimatic-iwy-light-master/app/vendor/spectrum.js"
          mobileFrontend.registerAssetFile 'css', "pimatic-iwy-light-master/app/vendor/spectrum.css"
        else
          env.logger.warn "your plugin could not find the mobile-frontend. No gui will be available"

  class IwyLightMaster extends env.devices.Device
    WHITE_MODE: 'WHITE'
    COLOR_MODE: 'COLOR'

    getTemplateName: -> "iwy-light-master"

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


    template: "iwy-light-master"

    actions:
      setPower:
        description: "turns the light on or off"
        params:
          state:
            type: t.string
      getPower:
        description: "returns the current state of the light"
        returns:
          state:
            type: t.boolean
      getMode:
        description: "returns the color mode"
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

      @device = new Iwy_master config.addr
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

    setPower: (newPower) ->
      return Promise.resolve() if @power is newPower
      if newPower is 'on'
        @device.switchOn @_updateState.bind(@)

      if newPower is 'off'
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


  class SwitchActionHandler extends env.actions.ActionHandler
    constructor: (@device, @state) ->

    executeAction: (simulate) =>
      if simulate
        return Promise.resolve(__("would switch #{@state}"))
      else
        @device.setPower @state
        return Promise.resolve(__("switched #{@state}"))

  class SwitchActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->

    parseAction: (input, context) =>
      iwyDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("setPower")
      ).value()

      # Try to match the input string with: turn|switch ->
      m = M(input, context).match(['turn ', 'switch '])

      device = null
      state = null
      match = null

      # device name -> on|off
      m.matchDevice iwyDevices, (m, d) ->
        m.match [' on', ' off'], (m, s) ->

          # Already had a match with another device?
          if device? and device.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return
          device = d
          state = s.trim()
          match = m.getFullMatch()

      # on|off -> deviceName
      m.match ['on ', 'off '], (m, s) ->
        m.matchDevice iwyDevices, (m, d) ->
          # Already had a match with another device?
          if device? and device.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return
          device = d
          state = s.trim()
          match = m.getFullMatch()

      if match?
        assert device?
        assert state in ['on', 'off']
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SwitchActionHandler(device, state)
        }
      else
        return null


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

  return new IwyLightMasterPlugin()
