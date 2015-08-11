sinon = require 'sinon'
{ MilightController } = require 'node-milight-promise'

class DriverStub
  @sendCommands = sinon.stub MilightController.prototype, 'sendCommands'

  @reset: ->
    @sendCommands.reset()

exports.DriverStub = DriverStub
