module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  nodeMilightRF24 = require 'node-milight-rf24'
  Buttons = nodeMilightRF24.RGBWButtons
  nodeMilightRF24 =  nodeMilightRF24.MilightRF24Controller
  BaseLedLight = require('./base')(env)
  
  class MilightRF24
    constructor: (@config) ->
      @gateway = new nodeMilightRF24({port: @config.MilightRF24Port})
      env.logger.debug "Opening "+@config.MilightRF24Port
      @gateway.open()

      @gateway.on("Received", (data) ->
        env.logger.debug data
      )
    
    getGateway: ->
      @gateway
    
    getDevice: (config, lastState) ->
      new MilightRF24Zone(config, lastState, @)
      
    setColor: (id, zone, r,g,b) ->
      env.logger.debug "Sending Color. Addr:"+id+" Zone:"+zone+" Red:"+r+" Green:"+g+" Blue:"+b
      @gateway.setColor(id, zone, r,g,b)
      
    setBrightness: (id, zone, brightness) ->
      env.logger.debug "Sending Brightness. Addr:"+id+" Zone:"+zone+" Brightness:"+brightness
      @gateway.setBrightness(id, zone, brightness)
      
    setWhite: (id, zone) ->
      env.logger.debug "Sending Whitemode. Addr:"+id+" Zone:"+zone
      switch zone
        when 0
          button = Buttons.AllOn
        when 1
          button = Buttons.Group1On
        when 2
          button = Buttons.Group2On
        when 3
          button = Buttons.Group3On
        when 4
          button = Buttons.Group4On
      
      @gateway.sendButton(id, zone, button, true)
      
    turnOn: (id, zone) ->
      env.logger.debug "Sending On. Addr:"+id+" Zone:"+zone
      switch zone
        when 0
          button = Buttons.AllOn
        when 1
          button = Buttons.Group1On
        when 2
          button = Buttons.Group2On
        when 3
          button = Buttons.Group3On
        when 4
          button = Buttons.Group4On
      
      @gateway.sendButton(id, zone, button, false)
      
    turnOff: (id, zone) ->
      env.logger.debug "Sending Off. Addr:"+id+" Zone:"+zone
      switch zone
        when 0
          button = Buttons.AllOff
        when 1
          button = Buttons.Group1Off
        when 2
          button = Buttons.Group2Off
        when 3
          button = Buttons.Group3Off
        when 4
          button = Buttons.Group4Off
      
      @gateway.sendButton(id, zone, button, false)
    
  class MilightRF24Zone extends BaseLedLight

    constructor: (@config, lastState, MilightRF24Gateway) ->
      self = @
      @device = @
      @gateway = MilightRF24Gateway
      @zones = @config.zones
      @brightness = 100
      @color = "FFFF00"
      
      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)
      if @power then @turnOn() else @turnOff()
      
      @gateway.getGateway().on('Received', (data) ->
      
        num2Hex: (s) ->
          a = s.toString(16);
          if (a.length % 2) > 0 
           a = "0" + a;
          a;
        
        for z in self.zones
          do br = (z) =>
            unless z.receive is false
              if z.addr is data.id and z.zone is data.zone
                env.logger.debug data
                switch data.button 
                  when Buttons.AllOn, Buttons.Group1On, Buttons.Group2On, Buttons.Group3On, Buttons.Group4On
                    self.turnOn()
                  when Buttons.AllOff, Buttons.Group1Off, Buttons.Group2Off, Buttons.Group3Off, Buttons.Group4Off
                    self.turnOff()
                  when (Buttons.AllOn or Buttons.Group1On or Buttons.Group2On or Buttons.Group3On or Buttons.Group4On) and data.longPress is true
                    self.setWhite()
                  when Buttons.ColorFader or Buttons.FaderReleased
                    self.setColor("#"+num2Hex(data.color.r)+num2Hex(data.color.g)+num2Hex(data.color.b))
                  when Buttons.BrightnessFader or Buttons.FaderReleased
                    self.setBrightness(data.brightness)
                  
                return yes
                
              return no
            
          if br is yes
            break
      )

    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    turnOn: ->
      env.logger.debug "Turn on"
      self = @
      @_updateState power: true
      
      for z in @zones
        do (z) =>
          unless z.send is false
            self.gateway.turnOn(z.addr, z.zone)
            if self.mode
              color = Color(self.color).rgb()
              self.gateway.setColor(z.addr, z.zone, color.r, color.g, color.b, true)
            else
              self.gateway.setWhite(z.addr, z.zone)
              
            self.gateway.setBrightness(z.addr, z.zone, self.brightness)
      Promise.resolve()

    turnOff: ->
      self = @
      @_updateState power: false
      for z in @zones
        do (z) =>
          unless z.send is false
            self.gateway.turnOff(z.addr, z.zone)
      Promise.resolve()

    setColor: (newColor) ->
      self = @
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      
      for z in @zones
        do (z) =>
          unless z.send is false
            self.gateway.setColor(z.addr, z.zone, color.r, color.g, color.b, true) if self.power
      Promise.resolve()

    setWhite: () ->
      self = @
      @_updateState mode: @WHITE_MODE
      
      for z in @zones
        do (z) =>
          unless z.send is false
            self.gateway.setWhite(z.addr, z.zone) if self.power
      Promise.resolve()

    setBrightness: (newBrightness) ->
      self = @
      @_updateState brightness: newBrightness
      for z in @zones
        do (z) =>
          unless z.send is false
            self.gateway.setBrightness(z.addr, z.zone, newBrightness) if self.power

      Promise.resolve()

  return MilightRF24
