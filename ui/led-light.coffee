$(document).on 'templateinit', (event) ->

  # define the item class
  class LedLightItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super

      @id = templData.deviceId

      @power = null
      @brightness = null
      @color = null
      @hue = 0

    afterRender: (elements) ->
      super
      ### Apply UI elements ###

      @powerSlider = $(elements).find('.light-power')
      @powerSlider.flipswitch()
      $(elements).find('.ui-flipswitch').addClass('no-carousel-slide')

      @brightnessSlider = $(elements).find('.light-brightness')
      @brightnessSlider.slider()

      @brightnessSliderTrack = $(elements).find('.light-brightness-slider-container .ui-slider-track')
      @brightnessSliderHandle = $(elements).find('.light-brightness-slider-container .ui-slider-handle')

      @colorSlider = $(elements).find('.light-color')
      @colorSlider.slider()

      @colorSliderTrack = $(elements).find('.light-color-slider-container .ui-slider-track')
      @_colorHandle = $(elements).find('.light-color-slider-container .ui-slider-handle')

      $(elements).find('.ui-slider').addClass('no-carousel-slide')

      @colorButton = $(elements).find('.popup-button')

      $('html').on 'click', (e) =>
        if $(elements).find('.popup-content-container').is(':hidden')
          return unless $(e.target).hasClass('popup-button')
          $(elements).find('.popup-content-container').show()
        else
          return if $(e.target).parents('.popup-content-container').length
          $(elements).find('.popup-content-container').hide()

      # $(elements).find('.popup-button').on 'click', ->
      #   $(elements).find('.popup-content-container').toggle()

      colorStops = []

      [0..360].forEach (hue, index) =>
        return if index and (index + 1) % 10
        colorStops.push @_hueColor(hue).css()

      @_gradientSlider @colorSliderTrack, colorStops

      @colorSlider.on 'change', (e) =>
        colorStops = []

        hue = $(e.target).val()
        return unless hue > 0

        @hue = hue
        colorCode = @_hueColor(@hue).hex()
        @_colorHandle.css 'background-color', colorCode

        [0..100].forEach (l, index) =>
          return if index and (index + 1) % 10
          colorStops.push @_hueColor(@hue, l).css()

        @_gradientSlider @brightnessSliderTrack, colorStops
        @brightnessSlider.trigger 'change', [origin: 'remote']

      @brightnessSlider.on 'change', (e) =>
        l = $(e.target).val()

        colorCode = @_hueColor(@hue, l).hex()
        @brightnessSliderHandle.css 'background-color', colorCode
        @colorButton.css 'background-color', colorCode

      @_onLocalChange 'power', @_setPower
      @_onLocalChange 'brightness', @_setBrightness
      @_onLocalChange 'color', @_setColor

      ### React on remote user input ###

      @_onRemoteChange 'power', @powerSlider
      @_onRemoteChange 'brightness', @brightnessSlider
      @_onRemoteChange 'color', @colorSlider

      @brightnessSlider.val(@brightness()).trigger 'change', [origin: 'remote']
      @powerSlider.val(@power()).trigger 'change', [origin: 'remote']
      @colorSlider.val(@_colorHue(@color())).trigger 'change', [origin: 'remote']


    _gradientSlider: (sliderTrack, colorStops) ->
      gradientWebkit = '-webkit-gradient(linear, left top, right top,'
      # distribute over a scale of 100%
      colorStepSize = 100 / colorStops.length

      colorStops.forEach (colorStop, index) =>
        gradientWebkit += "color-stop(#{colorStepSize * (index + 1)}%, #{colorStop})"
        gradientWebkit += if index is colorStops.length - 1 then ')' else ','

      sliderTrack.css background: gradientWebkit


    _hueColor: (hue, l=50) ->
      one.color "hsl(#{hue}, 80%, #{l}%)"

    _colorHue: (hexColor) ->
      return hexColor unless hexColor.match /^#/
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
        if attributeString is 'color'
          newValue = @_colorHue newValue

        @[attributeString] newValue
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
