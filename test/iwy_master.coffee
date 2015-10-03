should = require 'should'
{ env } = require './app_stub/env'
{ loadPluginWithEnvAndConfig } = require './app_stub/framework'
{ DriverStub } = require './driver_stubs/iwy_master'

describe 'IWY Master', ->
  device = null

  config =
    id: 'some_id'
    name: 'some_name'
    class: 'IwyMaster'
    addr: '127.0.0.1'

  beforeEach ->
    device = loadPluginWithEnvAndConfig env, 'IwyMaster', config

  afterEach ->
    DriverStub.reset()

  describe '#getPower', ->
    it 'should return the current power state (false by default)', (done) ->
      device.getPower().then (power) ->
        power.should.equal 'off'
        done()

  describe '#getMode', ->
    it 'should return the current power state (white by default)', (done) ->
      device.getMode().then (mode) ->
        mode.should.equal false
        done()

  describe '#turnOn', ->
    it 'should call the corresponding driver method', ->
      device.turnOn()
      DriverStub.switchOn.calledOnce.should.equal true

  describe '#turnOff', ->
    it 'should call the corresponding driver method', ->
      device.power = 'on'
      device.turnOff()
      DriverStub.switchOff.calledOnce.should.equal true

  describe '#toggle', ->
    it 'should switch the power state to ON when it is OFF before', ->
      device.power = 'off'
      device.toggle()
      DriverStub.switchOn.calledOnce.should.equal true
      DriverStub.switchOff.calledOnce.should.equal false

    it 'should switch the power state to OFF when it is ON before', ->
      device.power = 'on'
      device.toggle()
      DriverStub.switchOn.calledOnce.should.equal false
      DriverStub.switchOff.calledOnce.should.equal true

  describe '#setWhite', ->
    it 'should call the corresponding driver method', ->
      device.setWhite()
      DriverStub.setWhite.calledOnce.should.equal true

  describe '#setColor', ->
    it 'should call the corresponding driver method', ->
      device.setColor('#FFFFFF')
      DriverStub.setColor.calledOnce.should.equal true

  describe '#setBrightness', ->
    it 'should call the corresponding driver method', ->
      device.setBrightness(50)
      DriverStub.setBrightness.calledOnce.should.equal true

  describe '#changeDimlevelTo', ->
    it 'should call the corresponding driver method', ->
      device.changeDimlevelTo(50)
      DriverStub.setBrightness.calledOnce.should.equal true
