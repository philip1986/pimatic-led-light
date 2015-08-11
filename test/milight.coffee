should = require 'should'
{ env } = require './app_stub/env'
{ loadPluginWithEnvAndConfig } = require './app_stub/framework'
{ DriverStub } = require './driver_stubs/milight'
nodeMilight = require 'node-milight-promise'

describe 'Milight', ->
  device = null

  config =
    id: 'some_id'
    name: 'some_name'
    class: 'Milight'
    addr: '127.0.0.1'
    zone: 1

  beforeEach ->
    device = loadPluginWithEnvAndConfig env, 'Milight', config
    DriverStub.reset()

    # set default state
    device.mode = false
    device.color = ''
    device.power = 'off'
    device.brightness = 100


  describe '#getPower', ->
    it 'should return the current power state (off by default)', (done) ->
      device.getPower().then (power) ->
        power.should.equal 'off'
        done()

  describe '#getMode', ->
    it 'should return the current power state (white (false) by default)', (done) ->
      device.getMode().then (mode) ->
        mode.should.equal false
        done()

  describe '#turnOn', ->
    it 'should send the corresponding driver commands', ->
      device.turnOn()

      DriverStub.sendCommands.calledThrice.should.equal true
      # switch on the device
      DriverStub.sendCommands.firstCall.args[0].should.eql nodeMilight.commands.rgbw.on(config.zone)
      # set device into white mode
      DriverStub.sendCommands.secondCall.args[0].should.eql nodeMilight.commands.rgbw.whiteMode(config.zone)
      # set brigghtness
      DriverStub.sendCommands.thirdCall.args[0].should.eql nodeMilight.commands.rgbw.brightness(device.brightness)

  describe '#turnOff', ->
    it 'should send the corresponding driver commands', ->
      device.turnOff()
      DriverStub.sendCommands.calledOnce.should.equal true
      DriverStub.sendCommands.firstCall.args[0].should.eql nodeMilight.commands.rgbw.off(config.zone)

  # TODO: fix toggle methode in base class
  describe.skip '#toggle', ->
    it 'should switch the power state to ON when it is OFF before', ->
      device.power = 'off'
      device.toggle()

      DriverStub.sendCommands.calledThrice.should.equal true
      # just check that switch ON command is fired
      DriverStub.sendCommands.firstCall.args[0].should.eql nodeMilight.commands.rgbw.on(config.zone)

    it 'should switch the power state to OFF when it is ON before', ->
      device.power = 'on'
      device.toggle()

      DriverStub.sendCommands.calledOnce.should.equal true
      DriverStub.sendCommands.firstCall.args[0].should.eql nodeMilight.commands.rgbw.off(config.zone)

  describe '#setWhite', ->
    it 'should call the corresponding driver method', ->
      device.setWhite()

      DriverStub.sendCommands.calledTwice.should.equal true
      # first switch device to white mode
      DriverStub.sendCommands.firstCall.args[0].should.eql nodeMilight.commands.rgbw.whiteMode(config.zone)
      # second switch on (first argument) and set brightness (second argument)
      DriverStub.sendCommands.secondCall.args[0].should.eql nodeMilight.commands.rgbw.on(config.zone)
      DriverStub.sendCommands.secondCall.args[1].should.eql nodeMilight.commands.rgbw.brightness(device.brightness)

  # TODO: merge PR #25 from mwittig to fix broken code
  describe.skip '#setColor', ->
    it 'should call the corresponding driver method', ->
      device.setColor('#AAAAAA')
      device.power = 'on'

      DriverStub.sendCommands.calledOnce.should.equal true
      DriverStub.sendCommands.firstCall.args.should.eql [
        nodeMilight.commands.rgbw.on(config.zone)
        nodeMilight.commands.rgbw.rgb255(Number('0xAA'), Number('0xAA'), Number('0xAA'))
      ]

    context 'device power is "off"', ->
      it 'should call the corresponding driver method', ->
        device.setColor('#AAAAAA')
        device.power = 'off'

        DriverStub.sendCommands.called.should.equal false


  describe '#setBrightness', ->
    it 'should call the corresponding driver method', ->
      device.setBrightness(50)

      DriverStub.sendCommands.calledOnce.should.equal true
      DriverStub.sendCommands.firstCall.args.should.eql [
        nodeMilight.commands.rgbw.on(config.zone)
        nodeMilight.commands.rgbw.brightness(50)
      ]

  describe '#changeDimlevelTo', ->
    it 'should call the corresponding driver method', ->
      device.changeDimlevelTo(50)

      DriverStub.sendCommands.calledOnce.should.equal true
      DriverStub.sendCommands.firstCall.args.should.eql [
        nodeMilight.commands.rgbw.on(config.zone)
        nodeMilight.commands.rgbw.brightness(50)
      ]



