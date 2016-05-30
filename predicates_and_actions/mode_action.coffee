module.exports = (env) ->

  Promise = env.require 'bluebird'

  assert = require 'cassert'
  _ = require 'lodash'
  M = env.matcher

  class ModeActionHandler extends env.actions.ActionHandler
    constructor: (@provider, @device, @mode) ->

    executeAction: (simulate) =>
      getMode = (callback) =>
          callback @mode

      getMode @setMode
      
    setMode: (mode, simulate) =>
        if simulate
          return Promise.resolve(__("would log set mode #{mode}"))
        else
          @device.setMode mode
          return Promise.resolve(__("set mode #{mode}"))

  class ModeActionProvider extends env.actions.ActionProvider
      constructor: (@framework) ->

      parseAction: (input, context) =>
        iwyDevices = _(@framework.deviceManager.devices).values().filter(
          (device) => typeof device.setMode == 'function'
        ).value()

        hadPrefix = false

        # Try to match the input string with: set ->
        m = M(input, context).match(['set mode of '])
        
        device = null
        mode = null
        match = null
        variable = null

        # device name -> color
        m.matchDevice iwyDevices, (m, d) ->
          # Already had a match with another device?
          if device? and device.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return

          device = d

          if typeof device.setNight == 'function'
            m.match [' to '], (m) ->
              m.or [
                (m) ->
                  # TODO: forward pattern to UI
                  m.match ['night'], (m) ->
                    mode = 'NIGHT'
                    match = m.getFullMatch()
              ]
        
          if typeof device.setMode == 'function'
            m.match [' to '], (m) ->
              m.or [
                (m) ->
                  # TODO: forward pattern to UI
                  m.match ['white'], (m) ->
                    mode = 'WHITE'
                    match = m.getFullMatch()

                (m) ->
                  # TODO: forward pattern to UI
                  m.match ['color'], (m) ->
                    mode = 'COLOR'
                    match = m.getFullMatch()
              ]

        if match?
          assert device?
          # mode should be set
          assert mode?
          assert typeof match is "string"
          return {
            token: match
            nextInput: input.substring(match.length)
            actionHandler: new ModeActionHandler(@, device, mode)
          }
        else
          return null

  return ModeActionProvider
