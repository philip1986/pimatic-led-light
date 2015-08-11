sinon = require 'sinon'
{ EventEmitter } = require 'events'

self = @

exports.env =
  require: (lib) -> require lib
  devices:
    Device: class Device extends EventEmitter
  getDeviceEmitSpy: -> sinon.spy @devices.Device.prototype, 'emit'
  actions:
    ActionHandler: class ActionHandler
    ActionProvider: class ActionProvider
  plugins:
    Plugin: class Plugin
  logger:
    info: sinon.stub()
    warn: sinon.stub()
    error: sinon.stub()
