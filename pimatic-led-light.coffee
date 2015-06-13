module.exports = (env) ->

  # import device wrappers
  IwyMaster = require('./devices/iwy_master')(env)
  Milight = require('./devices/milight')(env)
  MilightRF24 = require('./devices/milightRF24')(env)
  Wifi370 = require('./devices/wifi370')(env)

  # import preadicares and actions
  ColorActionProvider = require('./predicates_and_actions/color_action')(env)

  class LedLightPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass 'IwyMaster',
        configDef: deviceConfigDef.LedLight
        createCallback: (config) -> return new IwyMaster(config)

      @framework.deviceManager.registerDeviceClass 'Wifi370',
        configDef: deviceConfigDef.Wifi370
        createCallback: (config) -> return new Wifi370(config)

      @framework.deviceManager.registerDeviceClass 'Milight',
        configDef: deviceConfigDef.Milight
        createCallback: (config, lastState) -> return new Milight(config, lastState)
        
      @framework.deviceManager.registerDeviceClass 'MilightRF24',
        configDef: deviceConfigDef.MilightRF24
        createCallback: (config, lastState) -> return MilightRF24.getDevice(config, lastState)

      @framework.ruleManager.addActionProvider(new ColorActionProvider(@framework))

      # wait till all plugins are loaded
      @framework.on "after init", =>
        # Check if the mobile-frontend was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', 'pimatic-led-light/ui/led-light.coffee'
          mobileFrontend.registerAssetFile 'css', 'pimatic-led-light/ui/led-light.css'
          mobileFrontend.registerAssetFile 'html', 'pimatic-led-light/ui/led-light.html'
          mobileFrontend.registerAssetFile 'js', 'pimatic-led-light/ui/vendor/spectrum.js'
          mobileFrontend.registerAssetFile 'css', 'pimatic-led-light/ui/vendor/spectrum.css'
        else
          env.logger.warn 'your plugin could not find the mobile-frontend. No gui will be available'


  return new LedLightPlugin()
