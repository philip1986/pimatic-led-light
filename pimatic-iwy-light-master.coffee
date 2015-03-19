
module.exports = (env) ->
  Promise = env.require 'bluebird'
  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  t = env.require('decl-api').types
  Iwy_master = require 'iwy_master'


  class IwyLightMasterPlugin extends env.plugins.Plugin


    init: (app, @framework, @config) =>
      deviceConfigDef = require("./iwy-light-master-schema")

      @framework.deviceManager.registerDeviceClass "IwyLightMaster",
        configDef: deviceConfigDef
        createCallback: (config) -> new IwyLightMaster(config)

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
      @device = new Iwy_master()
      @device.connect config.addr

      @device.on 'error', (err) ->
        console.log 'light error:', err

      @name = @config.name
      @id = @config.id

      # set inital state
      @color = '#FFFFFF'
      @setWhite()
      @setBrightness 70
      @setPower('on')
      super


    getPower: -> Promise.resolve @power
    getColor: -> Promise.resolve @color
    getMode: -> Promise.resolve @mode
    getBrightness: -> Promise.resolve @brightness

    setPower: (@power) ->
      console.log 'called'
      @device.switchOn() if power is 'on'
      @device.switchOff() if power is 'off'
      @emit 'power', power
      Promise.resolve()

    setColor: (colorCode) ->
      @mode = @COLOR_MODE
      @color = colorCode

      @emit 'color', colorCode

      return @setWhite() if colorCode.toUpperCase() is '#FFFFFF'

      red  = Number("0x#{colorCode[1..2]}")
      green = Number("0x#{colorCode[3..4]}")
      blue = Number("0x#{colorCode[5..6]}")

      @device.setColorRGB  red, green, blue
      @setBrightness 50

      Promise.resolve()

    setWhite: ->
      @mode = false
      @color = '#FFFFFF'
      @emit 'color', '#FFFFFF'
      @device.setWhite()
      Promise.resolve()

    setBrightness: (brightnessValue) ->
      @brightness = brightnessValue
      @emit 'brightness', brightnessValue

      @device.setBrightness brightnessValue
      Promise.resolve()


  return new IwyLightMasterPlugin()
