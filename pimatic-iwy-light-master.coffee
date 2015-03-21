module.exports = (env) ->
  Promise = env.require 'bluebird'

  t = env.require('decl-api').types
  Iwy_master = require 'iwy_master'
  _ = require 'lodash'
  assert = require 'cassert'


  M = env.matcher


  class IwyLightMasterPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./iwy-light-master-schema")

      @framework.deviceManager.registerDeviceClass "IwyLightMaster",
        configDef: deviceConfigDef
        createCallback: (config) -> return new IwyLightMaster(config)

      @framework.ruleManager.addActionProvider(new AnswerActionProvider(@framework))


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

      @device = new Iwy_master()
      @device.on 'error', (err) ->
        console.log 'light error:', err

      @power = null
      @color = null
      @brightness = null
      @mode = null

      @device.connect config.addr, =>
        @_sync()
        setInterval =>
          @_sync()
        , 3000
      super()

    _sync: ->
      @device.getState (err, state) =>
        return unless state

        if state.mode is @WHITE_MODE
          hexColor = ''

        if state.mode is @COLOR_MODE
          hexColor = '#'
          hexColor += state.color.r.toString(16)
          hexColor += state.color.g.toString(16)
          hexColor += state.color.b.toString(16)

        unless @power is state.power
          @emit 'power', if state.power then 'on' else 'off'
        unless @color is hexColor
          @emit 'color', hexColor
        unless @brightness is state.brightness
          @emit 'brightness', state.brightness

    getPower: -> Promise.resolve @power
    getColor: -> Promise.resolve @color
    getMode: -> Promise.resolve @mode
    getBrightness: -> Promise.resolve @brightness

    setPower: (newPower) ->
      return Promise.resolve() if @power is newPower
      @power = newPower
      if @power is 'on'
        @device.switchOn =>
          @_sync()
      if @power is 'off'
        @device.switchOff =>
          @_sync()

      Promise.resolve()

    setColor: (newColor) ->
      return Promise.resolve() if @color is newColor
      @color = newColor

      red  = Number("0x#{@color[1..2]}")
      green = Number("0x#{@color[3..4]}")
      blue = Number("0x#{@color[5..6]}")

      @device.setColor red, green, blue, =>
        @_sync()
      Promise.resolve()

    setWhite: ->
      @device.setWhite =>
        @_sync()
      Promise.resolve()

    setBrightness: (newBrightness) ->
      return Promise.resolve() if @brightness is newBrightness
      @brightness = newBrightness

      @device.setBrightness @brightness, =>
        @_sync()
      Promise.resolve()


  class AnswerActionHandler extends env.actions.ActionHandler
    constructor: (@device, @state) ->

    executeAction: (simulate) =>
      console.log 'called'
      if simulate
        return Promise.resolve(__("would log 42"))
      else
        @device.setPower @state
        return Promise.resolve(__("switched #{@state}"))

  class AnswerActionProvider extends env.actions.ActionProvider
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
          console.log d

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
          actionHandler: new AnswerActionHandler(device, state)
        }
      else
        return null

  return new IwyLightMasterPlugin()
