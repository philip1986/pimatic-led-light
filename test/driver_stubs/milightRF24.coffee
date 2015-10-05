sinon = require 'sinon'
{ EventEmitter } = require 'events'
MilightRF24 = require 'node-milight-rf24'

# replace whole Controller class
MilightRF24.MilightRF24Controller = class FakeMilightRF24Controller extends EventEmitter
  constructor: (@config) ->
  open: ->
  setColor: ->
  setBrightness: ->
  sendButton: ->

class DriverStub
  @open = sinon.stub MilightRF24.MilightRF24Controller.prototype, 'open'
  @setColor = sinon.stub MilightRF24.MilightRF24Controller.prototype, 'setColor'
  @setBrightness = sinon.stub MilightRF24.MilightRF24Controller.prototype, 'setBrightness'
  @sendButton = sinon.stub MilightRF24.MilightRF24Controller.prototype, 'sendButton'

  @reset: ->
    @open.reset()
    @setColor.reset()
    @setBrightness.reset()
    @sendButton.reset()

exports.DriverStub = DriverStub
