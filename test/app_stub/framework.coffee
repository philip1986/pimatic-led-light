should = require 'should'
{ EventEmitter } = require 'events'

class Framework extends EventEmitter
  constructor: (deviceClass, deviceConfig) ->
    @device = null

    @deviceManager =
      registerDeviceClass: (args...) =>
        args[0].should.be.type 'string'
        args[1].should.have.property 'configDef'
        args[1].should.have.property 'createCallback'

        return unless args[0] is deviceClass
        @device = args[1].createCallback(deviceConfig)

    @ruleManager =
      addActionProvider: ->
    @pluginManager =
      getPlugin: ->

exports.loadPluginWithEnvAndConfig = (env, deviceClass, deviceConfig) ->
  plugin = new (require '../../pimatic-led-light')(env)
  framework = new Framework deviceClass, deviceConfig

  plugin.init null, framework,
    plugin: 'led-light'
    MilightRF24Port: '' # fix MilightRF24 integration in pimatic-led-light.coffee

  return framework.device

