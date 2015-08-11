sinon = require 'sinon'
IwyMasterDriver = require 'iwy_master'

class DriverStub
  defaultDeviceState:
    power: false
    mode: 'WHITE'
    brightness: 100
    color:
      r: 0
      g: 0
      b: 0

  @switchOn = sinon.stub IwyMasterDriver.prototype, 'switchOn'
  @switchOff = sinon.stub IwyMasterDriver.prototype, 'switchOff'
  @getStateStub = sinon.stub IwyMasterDriver.prototype, 'getState'
  @setColor = sinon.stub IwyMasterDriver.prototype, 'setColor'
  @setWhite = sinon.stub IwyMasterDriver.prototype, 'setWhite'
  @setBrightness = sinon.stub IwyMasterDriver.prototype, 'setBrightness'

  @reset: ->
    @switchOn.reset()
    @switchOff.reset()
    @getStateStub.reset()
    @setColor.reset()
    @setWhite.reset()
    @setBrightness.reset()

### default behavior ###
DriverStub.getStateStub.yields null, DriverStub.defaultDeviceState

exports.DriverStub = DriverStub
