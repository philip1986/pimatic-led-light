module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require('lodash')
  Color = require 'color'
  BaseLedLight = require('./base')(env)
  YeelightDriver = require 'node-yeelight'

  class Yeelight extends BaseLedLight
    @driverReady: null
    @driver: null
    @init: () ->
      unless Yeelight.driver?
        env.logger.debug 'Yeelight init'
        Yeelight.driverReady = new Promise (resolve) =>
          Yeelight.driver = new YeelightDriver()
          Yeelight.driver.on 'error', =>
            env.logger.error "Yeelight error: #{error}"

          Yeelight.driver.once 'ready', =>
            resolve()

          process.nextTick () =>
            Yeelight.driver.listen()


      return Yeelight.driverReady

    constructor: (@config, lastState) ->
      @device = @
      @deviceReady = new Promise (resolve, reject) =>

        @deviceHandler = (newDevice) =>
          env.logger.debug 'Yeelight device found', @_deviceDebug(newDevice)
          if newDevice.host is @config.addr
            if @light?
              clearInterval @discoverIntervalTimoutId if @discoverIntervalTimoutId?
              @discoverIntervalTimoutId = null
              env.logger.debug 'Yeelight device matched'
              @light = newDevice
              Yeelight.driver.connect @light
              Yeelight.driver.removeListener 'deviceadded', @deviceHandler
              Yeelight.driver.removeListener 'deviceupdated', @deviceHandler
              Yeelight.driver.on 'powerupdated', @powerupdatedHandler
              Yeelight.driver.on 'brightnessupdated', @brightnessupdatedHandler
              Yeelight.driver.on 'rgbupdated', @rgbupdatedHandler
              Yeelight.driver.emit 'powerupdated', @light
              Yeelight.driver.emit 'brightnessupdated', @light
              Yeelight.driver.emit 'rgbupdated', @light
              resolve()
            else
              @light = newDevice

        @disconnectHandler = (device) =>
          if @_matchDevice @light, device
            env.logger.debug 'Yeelight device disconnected'
            unless @connectTimeoutId?
              @connectTimeoutId = setTimeout () =>
                Yeelight.driver.connect @light
                @connectTimeoutId = null
              , 1000

              @connectHandler = (device) =>
                if @_matchDevice @light, device
                  env.logger.debug 'Yeelight device connected'
                  Yeelight.driver.setPower @light, @getState().power, 500
                  color = unless @getState().color is '' then Color(@getState().color).hexString() else '#FFFFFF'
                  Yeelight.driver.setRGB @light, parseInt("0x#{color[1..6]}"), 100
                  Yeelight.driver.setBrightness @light, @getState().brightness, 0
              Yeelight.driver.once 'deviceconnected', @connectHandler

        @powerupdatedHandler = (device) =>
          if @_matchDevice @light, device
            env.logger.debug 'Yeelight powerupdated event received'
            @_updateState power: device.power is 'on'

        @brightnessupdatedHandler = (device) =>
          if @_matchDevice @light, device
            env.logger.debug 'Yeelight brightnessudated event received'
            b = parseInt device.brightness
            if b isnt @getState.brightness
              @_updateState
                brightness: b

        @rgbupdatedHandler = (device) =>
          if @_matchDevice @light, device
            env.logger.debug 'Yeelight rgbudated event received'
            color = unless @getState().color is '' then Color(@getState().color).hexString() else '#FFFFFF'
            newColor = '#' + ('000000' + parseInt(device.rgb).toString 16).substr(-6)
            if newColor isnt color
              @_updateState
                color: newColor
                mode: if newColor is '#FFFFFF' then @WHITE_MODE else @COLOR_MODE

        Yeelight.init().then () =>
          @device = Yeelight.driver
          env.logger.debug 'Yeelight ready'
          Yeelight.driver.on 'deviceadded', @deviceHandler
          Yeelight.driver.on 'deviceupdated', @deviceHandler
          Yeelight.driver.on 'devicedisconnected', @disconnectHandler
          Yeelight.driver.discover()
          @discoverIntervalTimoutId = setInterval () =>
            Yeelight.driver.discover()
          , 5000

      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)

    destroy: () ->
      Yeelight.driver.removeListener 'devicedisconnected', @disconnectHandler if @disconnectHandler?
      Yeelight.driver.removeListener 'deviceconnected', @connectHandler if @connectHandler?
      Yeelight.driver.removeListener 'deviceadded', @deviceHandler if @deviceHandler?
      Yeelight.driver.removeListener 'devicedisconnected', @deviceHandler if @deviceHandler?
      Yeelight.driver.removeListener 'powerupdated', @powerupdatedHandler if @powerupdatedHandler?
      Yeelight.driver.removeListener 'brightnessupdated', @brightnessupdatedHandler if @brightnessupdatedHandler?
      Yeelight.driver.removeListener 'rgbupdated', @rgbupdatedHandler if @rgbupdatedHandler?
      clearInterval @discoverIntervalTimoutId if @discoverIntervalTimoutId?
      clearTimout @connectTimeoutId if @connectTimeoutId?
      super()

    _matchDevice: (a, b) ->
      a.location is b.location and a.id is b.id
      
    _deviceDebug: (device) ->
      if device?
        location: device.location + '/' + device.id
        power: device.power
        brightness: device.brightness
        rgb: device.rgb
      else
        location: 'none'

    _deviceReady: () ->
      @deviceReady

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    turnOn: ->
      @_deviceReady().then () =>
        @_updateState power: true
        Yeelight.driver.setPower @light, true, 500
        color = unless @getState().color is '' then Color(@getState().color).hexString() else '#FFFFFF'
        Yeelight.driver.setRGB @light, parseInt("0x#{color[1..6]}"), 100
        Yeelight.driver.setBrightness @light, @getState().brightness, 0
        Promise.resolve()

    turnOff: ->
      @_deviceReady().then () =>
        @_updateState power: false
        Yeelight.driver.setPower @light, false, 500
        Promise.resolve()

    setColor: (newColor) ->
      @_deviceReady().then () =>
        color = Color(newColor).rgb()
        @_updateState
          mode: @COLOR_MODE
          color: color
        Yeelight.driver.setRGB @light, parseInt("0x#{newColor[1..6]}"), 100
        Promise.resolve()

    setWhite: ->
      @_deviceReady().then () =>
        @_updateState
          mode: @WHITE_MODE
        Yeelight.driver.setRGB @light, parseInt("0xFFFFFF"), 100
        Promise.resolve()

    setBrightness: (newBrightness) ->
      @_deviceReady().then () =>
        if newBrightness is 0
          result = @turnOff()
        else
          result = @turnOn()

        result.then () =>
          Yeelight.driver.setBrightness @light, newBrightness, 0
          @_updateState brightness: newBrightness
