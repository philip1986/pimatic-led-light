module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  nodeMilightRF24 = require 'node-milight-rf24'
  Buttons = nodeMilightRF24.RGBWButtons
  NodeMilightRF24 =  nodeMilightRF24.MilightRF24Controller
  BaseLedLight = require('./base')(env)
  events = require('events')
  
  # Handles the connection to the arduino (receives and sends messages)
  class MilightRF24 extends events.EventEmitter
    # singelton gatway connetion
    @connectToGateway: (config) ->
      unless MilightRF24.instance
        MilightRF24.instance = new MilightRF24 config
      return MilightRF24.instance

    constructor: (@config) ->
      self = @
      @gateway = new NodeMilightRF24
        port: @config.port

      env.logger.debug "Opening #{@config.port}"
      @gateway.open()
      
      events.EventEmitter.call(this);

      @gateway.on("Sending", (data) ->
        env.logger.debug data
      )
      
      @gateway.on("Received", (data) ->
        env.logger.debug data
        
        self.emit("ReceivedData", data);
      )
    
    getGateway: ->
      @gateway
    
    getDevice: (config, lastState) ->
      new MilightRF24Zone(config, lastState, @)
    
    setColor: (id, zone, r,g,b) ->
      env.logger.debug "Sending Color. Addr: #{id} Zone: #{zone} Red: #{r} Green: #{g} Blue: #{b}"
      @gateway.setColor(id, zone, r,g,b)
      
      @_loop(id, zone, Buttons.ColorFader, false, 0, 0, r,g,b)
      
    setBrightness: (id, zone, brightness) ->
      env.logger.debug "Sending Brightness. Addr:#{id} Zone:#{zone} Brightness:#{brightness}"
      @gateway.setBrightness(id, zone, brightness)
      
      @_loop(id, zone, Buttons.BrightnessFader, false, 0, brightness, 0,0,0)
      
    setWhite: (id, zone) ->
      env.logger.debug "Sending Whitemode. Addr:#{id} Zone:#{zone}"
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
      
      @_loop(id, zone, button, true, 0, 0, 0,0,0)
     
    setNight: (id, zone) ->
      env.logger.debug "Sending Nightmode. Addr:#{id} Zone:#{zone}"
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
      
      @gateway.sendButton(id, zone, button, true)
      
      @_loop(id, zone, button, true, 0, 0, 0,0,0)
      
    turnOn: (id, zone) ->
      env.logger.debug "Sending On. Addr:#{id} Zone:#{zone}"
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
      
      @_loop(id, zone, button, false, 0, 0, 0,0,0)
      
    turnOff: (id, zone) ->
      env.logger.debug "Sending Off. Addr:#{id} Zone:#{zone}"
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
      
      @_loop(id, zone, button, false, 0, 0, 0,0,0)
  
    # loop for changes to zone 0 to be reflected by all other zones which have the same id
    _loop: (id, zone, button, longPress, discoMode, brightness, r, g, b) ->
      dataObj =
        raw: "loop",
        id: id,
        zone: zone,
        button: button,
        longPress: longPress,
        discoMode: discoMode,
        brightness: brightness,
        color:
          r: r,
          g: g,
          b: b
          
      @.emit("ReceivedData", dataObj);
  
  # registers for messages from the main class and checks if incoming messages are addressed at the registered ids and zone combination
  # sends changes from the gui to the main class, so that they are send to the arduino
  class MilightRF24Zone extends BaseLedLight
    NIGHT_MODE: 'NIGHT'

    constructor: (@config, lastState, MilightRF24Gateway) ->
      self = @
      @device = @
      @gateway = MilightRF24Gateway
      @zones = @config.zones
      @brightness = 100
      @color = "FFFF00"
      @onMode = @COLOR_MODE
      @looping = false
      
      initState = _.clone lastState
      for key, value of lastState
        initState[key] = value.value
      super(initState)
      if @power then @turnOn() else @turnOff()
      
      # register for incoming messages
      @gateway.on('ReceivedData', (data) ->
        self.zones.forEach (z) ->
          
          # check if this zone listens on the current zone from config
          unless z.receive is false
            if z.addr is data.id                          
              if z.zone is data.zone or data.zone is 0
                switch data.button 
                  when data.longPress is true and (Buttons.AllOn or Buttons.Group1On or Buttons.Group2On or Buttons.Group3On or Buttons.Group4On)
                    self.setWhite(false)
                  when data.longPress is true and (Buttons.AllOff or Buttons.Group1Off or Buttons.Group2Off or Buttons.Group3Off or Buttons.Group4Off)
                    self.setNight(false)
                  when Buttons.AllOn, Buttons.Group1On, Buttons.Group2On, Buttons.Group3On, Buttons.Group4On
                    self.turnOn(false)
                  when Buttons.AllOff or (Buttons.Group1Off and z.zone is 1)  or (Buttons.Group2Off and z.zone is 2) or (Buttons.Group3Off and z.zone is 3)  or (Buttons.Group4Off and z.zone is 4)
                    self.turnOff(false)
                  when Buttons.ColorFader or Buttons.FaderReleased
                    self.setColor("#"+self._num2Hex(data.color.r)+self._num2Hex(data.color.g)+self._num2Hex(data.color.b), false)
                  when Buttons.BrightnessFader or Buttons.FaderReleased
                    self.setBrightness(data.brightness, false)
      )

    _num2Hex: (s) ->
      a = s.toString(16);
      if (a.length % 2) > 0 
        a = "0" + a;
      a;
      
    _updateState: (attr) ->
      state = _.assign @getState(), attr
      super null, state

    turnOn: (send) ->
      self = @
      
      @_updateState 
        mode: @onMode
        power: true
      
      @zones.forEach (z) ->
        unless z.send is false or send is false
          self.gateway.turnOn(z.addr, z.zone)
          
          unless z.zone is 0
            if self.mode
              color = Color(self.color).rgb()
              self.gateway.setColor(z.addr, z.zone, color.r, color.g, color.b, true)
            else
              self.gateway.setWhite(z.addr, z.zone)
              
            self.gateway.setBrightness(z.addr, z.zone, self.brightness)
        
      Promise.resolve()

    turnOff: (send) ->
      self = @
      
      @_updateState 
        mode: @onMode
        power: false
        
      @zones.forEach (z) ->
        unless z.send is false or send is false
          self.gateway.turnOff(z.addr, z.zone)
      Promise.resolve()

    setColor: (newColor, send) ->
      self = @
      color = Color(newColor).rgb()
      
      if @power
        @_updateState
          mode: @COLOR_MODE
          color: color
          
        @onMode = @COLOR_MODE
      
      @zones.forEach (z) ->
        unless z.send is false or send is false
          self.gateway.setColor(z.addr, z.zone, color.r, color.g, color.b, true) if self.power
      Promise.resolve()

    setWhite: (send) ->        
      self = @
      @_updateState mode: @WHITE_MODE
      
      @onMode = @WHITE_MODE
      
      @zones.forEach (z) ->
        unless z.send is false or send is false
          self.gateway.setWhite(z.addr, z.zone) if self.power
      Promise.resolve()

    setNight: (send) ->
      self = @
      @_updateState mode: @NIGHT_MODE
      
      @zones.forEach (z) ->
        unless z.send is false or send is false
          self.gateway.setNight(z.addr, z.zone)
      Promise.resolve()
    
    setMode: (mode) ->
      if mode is @NIGHT_MODE
        @setNight(true)
      else if mode is @WHITE_MODE
        @setWhite(true)
      else if mode is @COLOR_MODE
        @setColor(@color, true)
    
    setBrightness: (newBrightness, send) ->
      self = @

      if @power then @_updateState brightness: newBrightness
      
      @zones.forEach (z) ->
        unless z.send is false or send is false or self.looping is true
          self.gateway.setBrightness(z.addr, z.zone, newBrightness) if self.power

      if send is false
        @looping = true
      else
        @looping = false
      Promise.resolve()

  return MilightRF24
