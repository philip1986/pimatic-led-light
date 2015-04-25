# Driver interface requirements

This document describes requirements in regard to a light device driver interface.

__Note:__  *This is a proposal and might not compatible with the current implementaion. *

## General structure

- the driver must be provided as prototype (class)
- all options like host, port etc. must be passed by constructor

```
/**
 * @class
 */

var Driver = function(options) {
    this._host = options.host;
    this._port = options.port;
    this._zoneId = options.zoneId;
}
```

## Class variables
### Object with supported deivces
```
/** @member {array} DEVICES - List of supported devices */
Driver.DEVICES = ['iwy_master', 'wifi370']
```

## Public methodes
### Callback a public methode
All public methodes must yield `err` and `state` via a callbeck function.
```

methode = function(callback) {
    ...
    callback(err, state);
});
```
State must be an object with the following structure:
```
{
    power: true|false,              // mandatory
    mode: 'WHITE'|'COLOR',          // mandatory
    brightness: between 0 and 100,  // optional
    color: {                        // optional
        r: between 0 and 255,
        g: between 0 and 255,
        b: between 0 and 255
    }
}
```

### Mandatory methodes
#### switchOn
```
/**
 * Switch on the device
 *
 * @param {function} callback Yields err and state
 */

 Driver.prototype.switchOn = function(callback) {
    ...
 }
```

#### switchOff
```
/**
 * Switch off the device
 *
 * @param {function} callback Yields err and state
 */

 Driver.prototype.switchOff = function(callback) {
    ...
 }
```

#### getState
```
/**
 * Yields state of the device
 *
 * @param {function} callback Yields err and state
 */

 Driver.prototype.getState = function(callback) {
    ...
 }
```

### Optional methodes
#### setWhite
```
/**
 * Set device into warm withe mode
 *
 * @param {function} callback Yields err and state
 */

 Driver.prototype.setWhite = function(callback) {
    ...
 }
```

#### setColor
```
/**
 * Set color
 *
 * @param {number} red Amount of red in color mix between 0 and 255
 * @param {number} green Amount of green in color mix between 0 and 255
 * @param {number} blue Amount of blue in color mix between 0 and 255
 * @param {function} callback Yields err and state
 */

 Driver.prototypes.etColor(red, green, blue, callback) {
    ...
 }
```

#### setBrightness
```
/**
 * Set Brightness
 *
 * @param {number} value Percentage of light intensity between 0 and 100
 * @param {function} callback Yields err and state
 */

 Driver.prototypes.setBrightness(value, callback) {
    ...
 }
```
