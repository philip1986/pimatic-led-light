module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  nodeMilightRF24 = require 'MilightRF24Controller'
  BaseLedLight = require('./base')(env)
  
  class MilightRF24
    constructor: (config) ->
      @.gateway = new nodeMilightRF24({port: @config.MilightRF24Port})
      @.gateway.open()
      @.devices = new Array()
    
    getDevice: (config, lastState) ->
      if @.devices[config.id+"_"+config.zone] == undefined
        @.devices[config.id+"_"+config.zone] = new MilightRF24Zone(config, lastState, @)
        
      @.devices[config.id+"_"+config.zone]
      
    setColor: (id, zone, color, recurse) ->
      
    setBrightnes: (id, zone, brightnes, recurse) ->
      
    setWhite: (id, zone, recurse) ->
      
    turnOn: (id, zone, recurse) ->
      
    turnOff: (id, zone, recurse) ->
      
    
  class MilightRF24Zone extends BaseLedLight

    constructor: (@config, lastState, MilightRF24Gateway) ->
      @gateway = MilightRF24Gateway
      @id = @config.id
      @zone = @config.zone

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
      @device.sendCommands(nodeMilight.commands.rgbw.on(@zone))
      if @mode
        color = Color(@color).rgb()
        @device.sendCommands(nodeMilight.commands.rgbw.rgb255(color.r, color.g, color.b))
      else
        @device.sendCommands(nodeMilight.commands.rgbw.whiteMode(@zone))
        @device.sendCommands(nodeMilight.commands.rgbw.brightness(@brightness))
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      @device.sendCommands(nodeMilight.commands.rgbw.off(@zone))
      Promise.resolve()

    setColor: (newColor) ->
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      @device.sendCommands(
        nodeMilight.commands.rgbw.on(@zone),
        nodeMilight.commands.rgbw.rgb255(color.r, color.g, color.b)
      ) if @power
      Promise.resolve()

    setWhite: () ->
      @_updateState mode: @WHITE_MODE
      @device.sendCommands(nodeMilight.commands.rgbw.whiteMode(@zone)) if @power
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      @device.sendCommands(
        nodeMilight.commands.rgbw.on(@zone),
        nodeMilight.commands.rgbw.brightness(@brightness)
      ) if @power

      Promise.resolve()

  return MilightRF24
