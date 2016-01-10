module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = require 'lodash'
  Color = require 'color'
  nodeMilight = require 'node-milight-promise'
  BaseLedLight = require('./base')(env)


  class MilightCWWW extends BaseLedLight

    constructor: (@config, lastState) ->
      @device = new nodeMilight.MilightController
        ip: @config.addr
        delayBetweenCommands: 50
        commandRepeat: 2

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

      @device.sendCommands(nodeMilight.commands.white.on(@zone))
      @device.sendCommands(nodeMilight.commands.white.maxBright())

      Promise.resolve()

    turnOff: ->
      @_updateState power: false

      @device.sendCommands(nodeMilight.commands.white.off(@zone))        

      Promise.resolve()

  return MilightCWWW
