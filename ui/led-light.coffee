$(document).on 'templateinit', (event) ->

  # define the item class
  class LedLightItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super

      # load supported modes from config if available
      @supportedModes =  @device.config.supportedModes or ['WHITE', 'COLOR']

      @id = templData.deviceId

      @power = null
      @brightness = null
      @color = null
      @hue = null
      @mode = null

    afterRender: (elements) ->
      super
      ### Apply UI elements ###

      @powerSlider = $(elements).find('.light-power')
      @powerSlider.flipswitch()

      @modeElement = $(elements).find('.light-mode')

      $(elements).find('.ui-flipswitch').addClass('no-carousel-slide')

      @brightnessSlider = $(elements).find('.light-brightness')
      @brightnessSlider.slider()

      @brightnessSliderTrack = $(elements).find('.light-brightness-slider-container .ui-slider-track')
      @brightnessSliderHandle = $(elements).find('.light-brightness-slider-container .ui-slider-handle')

      @colorSliderContainer = $(elements).find('.light-color-slider-container')
      @colorSlider = $(elements).find('.light-color')
      @colorSlider.slider()

      @colorSliderTrack = $(elements).find('.light-color-slider-container .ui-slider-track')
      @_colorHandle = $(elements).find('.light-color-slider-container .ui-slider-handle')

      $(elements).find('.ui-slider').addClass('no-carousel-slide')

      @colorButton = $(elements).find('.popup-button')

      @modeButtons =
        WHITE: $(elements).find('.white-mode-btn')
        COLOR: $(elements).find('.color-mode-btn')
        TEST: $(elements).find('.test-mode-btn')

      for name, button of @modeButtons
        unless name in @supportedModes
          button.hide()

      $(elements).find('.mode-btn:visible').first().addClass('ui-first-child')
      $(elements).find('.mode-btn:visible').last().addClass('ui-last-child')

      $('html').on 'click', (e) =>
        if $(elements).find('.popup-content-container').is(':hidden')
          return unless $(e.target).hasClass 'popup-button'
          return unless $(elements).find(e.target).length
          $(elements).find('.popup-content-container').show()
        else
          return if $(e.target).parents('.popup-content-container').length
          $(elements).find('.popup-content-container').hide()


      @colorSlider.on 'change', (e, payload) =>

        @hue = $(e.target).val()
        return unless @hue > 0

        colorCode = @_hueColor(@hue).hex()
        @_colorHandle.css 'background-color', colorCode

        @_renderColorSlider()
        @_renderBrightnessSlider @hue

        @brightnessSlider.val Math.round(@_hexColor(@color()).l() * 99)
        @brightnessSlider.trigger 'change', [origin: 'remote']

      @brightnessSlider.on 'change', (e) =>
        l = $(e.target).val()
        return unless @hue

        l = 30 if l < 30
        l = 80 if l > 80
        colorCode = @_hueColor(@hue, l).hex()
        @brightnessSliderHandle.css 'background-color', colorCode
        @colorButton.css 'background-color', colorCode

      @_onLocalChange 'power', @_setPower
      @_onLocalChange 'brightness', @_setBrightness
      @_onLocalChange 'color', @_setColor
      @_onLocalChange 'mode', @_setMode

      ### React on remote user input ###

      @modeElement.on 'change', (e) =>
        mode = $(e.target).val()
        if mode is 'WHITE'
          @_adjustUIforWhiteMode()
        if mode is 'COLOR'
          @_adjustUIforColorMode()

      @_onRemoteChange 'power', @powerSlider
      @_onRemoteChange 'brightness', @brightnessSlider
      @_onRemoteChange 'color', @colorSlider
      @_onRemoteChange 'mode', @modeElement

      @powerSlider.val(@power()).trigger 'change', [origin: 'remote']
      @colorSlider.val(@_colorHue(@color())).trigger 'change', [origin: 'remote']
      @brightnessSlider.val(@brightness()).trigger 'change', [origin: 'remote']
      @modeElement.val(@mode()).trigger 'change', [origin: 'remote']

    selectMode: (mode) ->
      @modeElement?.val(mode).trigger 'change'
      return null

    _select: (mode) ->
      for key, modeButton of @modeButtons
        modeButton.removeClass 'mode-button-selected'
      @modeButtons[mode].addClass 'mode-button-selected'

    _adjustUIforWhiteMode: ->
      @hue = 60

      @colorSliderContainer?.hide()
      @_renderBrightnessSlider @hue
      @brightnessSlider.trigger 'change', [origin: 'remote']
      @_select 'WHITE'

    _adjustUIforColorMode: ->
      colorCode = @color()
      @hue = @_colorHue colorCode
      @colorSliderContainer?.show()
      @_renderBrightnessSlider @hue
      @brightnessSlider.trigger 'change', [origin: 'remote']
      @colorSlider.val(@hue).trigger 'change', [origin: 'remote']
      @_select 'COLOR'


    _setMode: (mode) ->
      if mode is 'WHITE'
        @_adjustUIforWhiteMode()
        return @device.rest.setWhite {}, global: no
      if mode is 'COLOR'
        @_adjustUIforColorMode()
        return @device.rest.setColor {colorCode: @color()},  global: no

    _renderBrightnessSlider: (hue) ->
      colorStops = []

      [30..80].forEach (l, index) =>
        return if index and (index + 1) % 10
        colorStops.push @_hueColor(hue, l).css()

      @_gradientSlider @brightnessSliderTrack, colorStops

    _renderColorSlider: ->
      colorStops = []

      [0..360].forEach (hue, index) =>
        return if index and (index + 1) % 10
        colorStops.push @_hueColor(hue).css()

      @_gradientSlider @colorSliderTrack, colorStops

    _gradientSlider: (sliderTrack, colorStops) ->
      return unless sliderTrack
      gradient = 'linear-gradient(to right, '
      # distribute over a scale of 100%
      colorStepSize = 100 / colorStops.length

      colorStops.forEach (colorStop, index) =>
        gradient += "#{colorStop} #{colorStepSize * (index + 1)}%"
        gradient += if index is colorStops.length - 1 then ')' else ','

      sliderTrack.css background: gradient

    _hexColor: (hexColor) ->
      return one.color(hexColor).hsl()

    _hueColor: (hue, l=50) ->
      one.color "hsl(#{hue}, 80%, #{l}%)"

    _colorHue: (hexColor) ->
      return hexColor unless "#{hexColor}".match /^#/
      Math.round(one.color(hexColor).hsl().h() * 360)

    _onLocalChange: (element, fn) ->
      timeout = 500  # ms

      # only execute one command at the time
      # delay the callback to protect the device against overflow
      queue = async.queue (arg, cb) =>

        fn.call(@, arg)
          .done( (data) ->
            ajaxShowToast
            setTimeout cb, timeout
          )
          .fail( (data) ->
            ajaxAlertFail(data)
            setTimeout cb, timeout
          )
      , 1 # concurrency

      $('#index').on "change", "#item-lists ##{@id} .light-#{element}", (e, payload) =>
        return if payload?.origin is 'remote'
        return if @[element]?() is $(e.target).val()

        # flush queue to do not pile up commands
        # latest command has highest priority
        queue.kill() if queue.length() > 2
        queue.push $(e.target).val()

    _onRemoteChange: (attributeString, el) ->
      attribute = @getAttribute(attributeString)

      unless attributeString?
        throw new Error("A LED-Light device needs an #{attributeString} attribute!")

      @[attributeString] = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        @[attributeString] newValue

        if attributeString is 'color'
          el.val(@_colorHue newValue).trigger 'change', [origin: 'remote']
        else
          el.val(@[attributeString]()).trigger 'change', [origin: 'remote']

    _setPower: (state) ->
      if state is 'on'
        @device.rest.turnOn {}, global: no
      else
        @device.rest.turnOff {}, global: no

    _setColor: (hue) ->
      unless hue
        return @device.rest.setWhite {}, global: no

      colorCode = @_hueColor(hue).hex()

      @device.rest.setColor {colorCode: colorCode},  global: no

    _setBrightness: (brightnessValue) ->
      @device.rest.setBrightness {brightnessValue: brightnessValue}, global: no

  # register the item-class
  pimatic.templateClasses['led-light'] = LedLightItem
