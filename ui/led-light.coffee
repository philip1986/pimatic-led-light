$(document).on 'templateinit', (event) ->

  # define the item class
  class LedLightItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super

      @id = templData.deviceId

      @debounceTimerId = null

      @power = null
      @brightness = null
      @color = null

    afterRender: (elements) ->
      super
      ### Apply UI elements ###

      @powerSlider = $(elements).find('.light-power')
      @powerSlider.flipswitch()
      $(elements).find('.ui-flipswitch').addClass('no-carousel-slide')

      @brightnessSlider = $(elements).find('.light-brightness')
      @brightnessSlider.slider()
      $(elements).find('.ui-slider').addClass('no-carousel-slide')

      @colorPicker = $(elements).find('.light-color')
      @colorPicker.spectrum
        preferredFormat: 'hex'
        showButtons: false
        allowEmpty: true
        move: (color) =>
          return @colorPicker.val(null).change() unless color
          @colorPicker.val("##{color.toHex()}").change()

      @colorPicker.on 'change', (e, payload) =>
        return if payload?.origin unless 'remote'
        @colorPicker.spectrum 'set', $(e.target).val()

      @_onLocalChange 'power', @_setPower
      @_onLocalChange 'brightness', @_setBrightness
      @_onLocalChange 'color', @_setColor

      ### React on remote user input ###

      @_onRemoteChange 'power', @powerSlider
      @_onRemoteChange 'brightness', @brightnessSlider
      @_onRemoteChange 'color', @colorPicker

      @colorPicker.spectrum('set', @color())
      @brightnessSlider.val(@brightness()).trigger 'change', [origin: 'remote']
      @powerSlider.val(@power()).trigger 'change', [origin: 'remote']

    _debounce: (fn, timeout) ->
      clearTimeout @debounceTimerId if @debounceTimerId
      @debounceTimerId = setTimeout fn, timeout

    _onLocalChange: (element, fn) ->
      $('#index').on "change", "#item-lists ##{@id} .light-#{element}", (e, payload) =>
        return if payload?.origin is 'remote'
        return if @[element]?() is $(e.target).val()
        @_debounce =>
          fn.call @, $(e.target).val()
        , 50

    _onRemoteChange: (attributeString, el) ->
      attribute = @getAttribute(attributeString)

      unless attributeString?
        throw new Error("A LED-Light device needs an #{attributeString} attribute!")

      @[attributeString] = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        @[attributeString] newValue
        el.val(@[attributeString]()).trigger 'change', [origin: 'remote']

    _setPower: (state) ->

      if state is 'on'
        @device.rest.turnOn({}, global: no)
          .done(ajaxShowToast)
          .fail(ajaxAlertFail)
      else
        @device.rest.turnOff({}, global: no)
          .done(ajaxShowToast)
          .fail(ajaxAlertFail)

    _setColor: (colorCode) ->
      unless colorCode
        @device.rest.setWhite({}, global: no)
          .done(ajaxShowToast)
          .fail(ajaxAlertFail)
      else
        @device.rest.setColor({colorCode: colorCode},  global: no)
          .done(ajaxShowToast)
          .fail(ajaxAlertFail)

    _setBrightness: (brightnessValue) ->
      @device.rest.setBrightness({brightnessValue: brightnessValue}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)

  # register the item-class
  pimatic.templateClasses['led-light'] = LedLightItem
