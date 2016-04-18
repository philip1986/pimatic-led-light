module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require('lodash')
  Color = require 'color'
  BaseLedLight = require('./base')(env)

  class DummyLedLight extends BaseLedLight

    constructor: (@config, lastState) ->
      @device = @
      @name = @config.name
      @id = @config.id
      @_dimlevel = lastState?.dimlevel?.value or 0

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
      Promise.resolve()

    turnOff: ->
      @_updateState power: false
      Promise.resolve()

    setColor: (newColor) ->
      color = Color(newColor).rgb()
      @_updateState
        mode: @COLOR_MODE
        color: color
      Promise.resolve()

    setWhite: ->
      @_updateState mode: @WHITE_MODE
      Promise.resolve()

    setBrightness: (newBrightness) ->
      @_updateState brightness: newBrightness
      Promise.resolve()

  return DummyLedLight
