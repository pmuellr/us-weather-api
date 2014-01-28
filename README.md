us-weather-api
================================================================================

This node package provides a library of functions to obtain weather forecasts
from locations in the United States.  The weather data is obtained from
[a REST service provided by the National Weather Service](http://graphical.weather.gov/xml/rest.php).



module exports
================================================================================

The module exports the following objects and functions:



`version`
--------------------------------------------------------------------------------

The version property is the [semver](http://semver.org/spec/v2.0.0.html) version
of the package.



`getLocations(callback)`
--------------------------------------------------------------------------------

Returns an object which contains a list of known locations and their geographic
coordinates.

The object has a single property `locations`, which is an array of Location
objects.

A Location object has the following properties:

* `lat`   - the latitude of the location; a Number
* `lon`   - the longitude of the location; a Number
* `city`  - the name of the city of the location
* `state` - the two letter abbreviation of the state of the location



`getWeatherByZip(zipcode, callback)`
--------------------------------------------------------------------------------

Returns a Weather object for the given zipcode.

The `zipcode` parameter should be a string.

The Weather object contains the following properties:

* `date` - a [`Date.parse()-able` date string][date-parse]
* `lat` - the latitude of the location; a Number
* `lon` - the longitude of the location; a Number
* `forecast` - an object containing forecast data

The forecast object has [`Date.parse()-able` date strings][date-parse] as
keys.  The values associated with those keys are an object which contains
properties for various forecast values.

The properties in the forecast values can be:

* `temp`     - Temperature
* `dew`      - Dew Point Temperature
* `appt`     - Apparent Temperature
* `pop12`    - 12 Hourly Probability of Precipitation
* `qpf`      - Liquid Precipitation Amount
* `snow`     - Snow Amount
* `iceaccum` - Ice Accumulation
* `sky`      - Cloud Cover Amount
* `rh`       - Relative Humidity

Here's an example of a Weather object:

    {
        "date": "2014-01-28 20:36:03.000Z",
        "lat": 35.68,
        "lon": -78.82,
        "forecast": {
            "2014-01-27 19:00:00.000Z": {
                "qpf": 0
            },
            "2014-01-27 20:00:00.000Z": {
                "temp": 64,
                "dew": 34,
                "qpf": 0
            },
            ...
        }
    }



`getWeatherByGeo(lat, lon, callback)`
--------------------------------------------------------------------------------

Returns a Weather object for the given latitude and longitude.

The `lat` and `lon` parameters should be numbers.

The Weather object is the same shape as returned by `getWeatherByZip()`.



callbacks
================================================================================

The `callback` parameter in the module functions are "standard" node callbacks
which are passed two arguments: an `error` and the `data`.  Here's an example
of handling the `getLocations()` function:

    weather = require("us-weather-api")

    weather.getLocations(function(err, data) {
        console.log("getLocations():")
        console.log("   error:", err)
        console.log("   data: ", data)
    })

In all cases where a callback is specified, you can instead have a
[q-flavored promise](http://documentup.com/kriskowal/q/) returned from the
function by not passing a callback.  Here's an example of using a function
with promises.

    weather = require("us-weather-api")

    promise = weather.getLocations()

    promise.then(function (data) {
        console.log("getLocations() data: ", data)
    })

    promise.fail(function (err) {
        console.log("getLocations() error: ", err)
    })

    promise.done()

<!-- ref -->
[date-parse]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/parse]



license
--------------------------------------------------------------------------------

Licensed under [the Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)
