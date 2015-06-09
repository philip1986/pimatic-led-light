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
      
    setColor: (id, zone, r,g,b) ->
      
    setBrightness: (id, zone, brightness) ->
      
    setWhite: (id, zone) ->
      
    turnOn: (id, zone) ->
      
    turnOff: (id, zone) ->
      
    
  class MilightRF24Zone extends BaseLedLight

    constructor: (@config, lastState, MilightRF24Gateway) ->
      @gateway = MilightRF24Gateway
      @zones = @config.zones

      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)
      if @power then @turnOn() else @turnOff()
      
      @gateway.on('dataReceived', (data) ->
        for z in @zones
          do br = (z) =>
            unless z.receive is false
              if z.addr is data.id and z.zone is data.group
                
                switch data.button 
                  when Buttons.AllOn, Buttons.Group1On, Buttons.Group2On, Buttons.Group3On, Buttons.Group4On
                    @turnOn()
                  when Buttons.AllOff, Buttons.Group1Off, Buttons.Group2Off, Buttons.Group3Off, Buttons.Group4Off
                    @turnOff()
                  when (Buttons.AllOn or Buttons.Group1On or Buttons.Group2On or Buttons.Group3On or Buttons.Group4On) and data.longPress is true
                    @turnOn()
                  when Buttons.ColorFader or Buttons.FaderReleased
                    @setColor(data.color)
                  when Buttons.BrightnessFader or Buttons.FaderReleased
                    @setBrightness(data.brightness)
                  
                return yes
                
              return no
            
          if br is yes
            break
      )

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    turnOn: ->
      @_updateState power: true
     
      for z in @zones
        do (z) =>
          unless z.send is false
            @gateway.turnOn(@z.addr, @z.zone)
            if @mode
              color = Color(@color).rgb()
              @gateway.setColor(@z.addr, @z.zone, color.r, color.g, color.b, true)
            else
              @gateway.setWhite(@z.addr, @z.zone)
              
            @gateway.setBrightness(@z.addr, @z.zone, @brightness))
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      for z in @zones
        do (z) =>
          unless z.send is false
            @gateway.turnOff(@z.addr, @z.zone)
      Promise.resolve()

    setColor: (newColor) ->
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      
      for z in @zones
        do (z) =>
          unless z.send is false
            @gateway.setColor(@z.addr, @z.zone, color.r, color.g, color.b, true) if @power
      Promise.resolve()

    setWhite: () ->
      @_updateState mode: @WHITE_MODE
      
      for z in @zones
        do (z) =>
          unless z.send is false
            @gateway.setWhite(@z.addr, @z.zone) if @power
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      for z in @zones
        do (z) =>
          unless z.send is false
            @gateway.setBrightness(@z.addr, @z.zone, newBrightness) if @power

      Promise.resolve()

  return MilightRF24
