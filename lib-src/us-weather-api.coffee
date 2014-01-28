# Licensed under the Apache License. See footer for details.

URL  = require "url"
http = require "http"
util = require "util"

Q          = require "q"
_          = require "underscore"
htmlParser = require "htmlparser"
soupSelect = require "soupselect"
select     = soupSelect.select

pkg = require "../package.json"

api = exports

#-------------------------------------------------------------------------------
URLprefix = "http://graphical.weather.gov/xml/sample_products/browser_interface/ndfdXMLclient.php"

DataNameMap =
    "Temperature":                              "temp"
    "Dew Point Temperature":                    "dew"
    "Apparent Temperature":                     "appt"
    "12 Hourly Probability of Precipitation":   "pop12"
    "Liquid Precipitation Amount":              "qpf"
    "Snow Amount":                              "snow"
    "Ice Accumulation":                         "iceaccum"
    "Cloud Cover Amount":                       "sky"
    "Relative Humidity":                        "rh"

DataSets = [
    [ 'temperature[type="hourly"]',   parseInt   ]
    [ 'temperature[type="dewpoint"]', parseInt   ]
    [ 'temperature[type="apparent"]', parseInt   ]
    [ 'precipitation[type="liquid"]', parseFloat ]
    [ 'precipitation[type="snow"]',   parseFloat ]
    [ 'precipitation[type="ice"]',    parseFloat ]
    [ 'cloudamount',                  parseInt   ]
    [ 'probabilityofprecipitation',   parseInt   ]
    [ 'humidity',                     parseInt   ]
]

WeatherParms = _.values DataNameMap
WeatherParms = _.map WeatherParms, (parm) -> "#{parm}=#{parm}"
WeatherParms = WeatherParms.join "&"

#-------------------------------------------------------------------------------
api.version = pkg.version

#-------------------------------------------------------------------------------
api.getLocations = (callback) ->
    {callback, result} = getCallbackAndResult callback

    url = "#{URLprefix}?listCitiesLevel=1234"

    getHttp url, (err, body) ->
        if err?
            err.weatherURL = url
            callback err
            return result

        try
            handle_getLocations body, callback
        catch err
            err.weatherURL = url
            callback err
            return result

    return result

#-------------------------------------------------------------------------------
api.getWeatherByZip = (zipcode, callback) ->
    {callback, result} = getCallbackAndResult callback

    parsedZipcode = parseInt "#{zipcode}"
    if isNaN parsedZipcode
        callback Error("zipcode value is not an integer")
        return result

    url = "#{URLprefix}?product=time-series&zipCodeList=#{zipcode}" # &#{WeatherParms}"

    # console.log url
    getHttp url, (err, body) ->
        if err?
            err.weatherURL = url
            callback err
            return result

        try
            handle_getWeather body, callback
        catch err
            err.weatherURL = url
            callback err
            return result

    return result

#-------------------------------------------------------------------------------
api.getWeatherByGeo = (lat, lon, callback) ->
    {callback, result} = getCallbackAndResult callback

    parsedLat = parseFloat "#{lat}"
    if isNaN parsedLat
        callback Error("latitude value is not a number")
        return result

    parsedLon = parseFloat "#{lon}"
    if isNaN parsedLon
        callback Error("longitude value is not a number")
        return result

    url = "#{URLprefix}?product=time-series&listLatLon=#{lat},#{lon}&#{WeatherParms}"

    # console.log url
    getHttp url, (err, body) ->
        if err?
            err.weatherURL = url
            callback err
            return result

        try
            handle_getWeather body, callback
        catch err
            err.weatherURL = url
            callback err
            return result

    return result

#-------------------------------------------------------------------------------
handle_getLocations = (xml, callback) ->

    dom = parseXML xml

    llList = getText select dom, "latlonlist"
    cnList = getText select dom, "citynamelist"

    llList = llList.split " "
    cnList = cnList.split "|"

    locations = []

    for i in [0...llList.length]
        ll = llList[i]
        cn = cnList[i]

        [ lat,  lon   ] = ll.split ","
        [ city, state ] = cn.split ","

        lat = parseFloat lat
        lon = parseFloat lon

        locations.push {lat, lon, city, state}

    callback null, {locations}

#-------------------------------------------------------------------------------
handle_getWeather = (xml, callback) ->
    # console.log "handle_getWeather(#{xml})"
    result = {}

    dom = parseXML xml

    result.date = getDate select dom, "creationdate"

    point = select(dom, "data location point")[0]

    result.lat = parseFloat point.attribs.latitude
    result.lon = parseFloat point.attribs.longitude

    timeLayouts = getTimeLayouts dom
    times       = getTimes timeLayouts

    result.forecast = forecast = {}
    for time in times
        forecast[time] = {}

    for [selector, parser] in DataSets
        {name, values} = getParameterData dom, timeLayouts, selector, parser
        continue if !name?

        name = DataNameMap[name]
        for {time, value} in values
            forecast[time][name] = value

    callback null, result

    return

#-------------------------------------------------------------------------------
getParameterData = (dom, timeLayouts, elementName, parser) ->
    # console.log "getParameterData #{elementName}"

    elements = select dom, "data parameters #{elementName}"
    return {} if !elements[0]?

    layout   = elements[0].attribs["time-layout"]
    return {} if !layout?

    layout   = timeLayouts[layout]
    return {} if !layout?

    name     = getText select elements, "name"
    values   = select elements, "value"
    return {} if !name? or !values?

    # console.log name, layout

    rawValues = _.map values, (value) -> valueParser value, parser

    len = Math.min values.length, layout.length

    values = []
    for i in [0...len]
        time  = layout[i]
        value = rawValues[i]

        values.push {time, value}

    return {name, values}

#-------------------------------------------------------------------------------
valueParser = (dom, fn) ->
    text  = getText dom

    if fn is parseInt
        value = parseInt text, 10
    else
        value = parseFloat text

    value = 0 if isNaN value

    return value

#-------------------------------------------------------------------------------
valueParserFloat = (dom) ->
    text  = getText dom
    value = parseFloat text
    value = 0.0 if isNaN value
    return value

#-------------------------------------------------------------------------------
getTimeLayouts = (dom) ->
    result = {}

    layoutElements = select dom, "timelayout"

    for layoutElement in layoutElements
        key = getText select layoutElement, "layoutkey"

        timeElements = select layoutElement, "startvalidtime"
        times = _.map timeElements, (timeElement) -> getDate timeElement

        result[key] = times

    return result

#-------------------------------------------------------------------------------
getTimes = (timeLayouts) ->
    timeKeys = {}
    for layout, times of timeLayouts
        for time in times
            timeKeys[time] = time

    timeKeys = _.keys timeKeys
    timeKeys = timeKeys.sort()

    return timeKeys

#-------------------------------------------------------------------------------
findElements = (nodes, tag, result) ->
    result = result || []

    for node in nodes
        if node.type is "tag"
            if node.name is tag
                result.push node

        if node.children?
            findElements(node.children, tag, result)

    return result

#-------------------------------------------------------------------------------
findElement = (nodes, tag, result) ->
    elements = findElements nodes, tag
    return elements[0]

#-------------------------------------------------------------------------------
getDate = (nodes) ->
    text = getText nodes
    date = new Date text
    return date.toISOString().replace("T", " ")

#-------------------------------------------------------------------------------
getText = (nodes, result) ->
    nodes = [nodes] if !_.isArray nodes

    result = result || ""

    for node in nodes

        if node.type is "text"
            result += node.data

        if node.children?
            result = getText(node.children, result)

    return result

#-------------------------------------------------------------------------------
parseXML = (body) ->
    result = null

    handler = new htmlParser.DefaultHandler (err, nodes) ->
        result = nodes if !err?

    parser = new htmlParser.Parser handler
    parser.parseComplete(body)

    normalizeElements result

    return result

#-------------------------------------------------------------------------------
# lowercase and remove - from element names
#-------------------------------------------------------------------------------
normalizeElements = (nodes) ->
    return if !nodes?

    nodes = [nodes] if !_.isArray nodes

    for node in nodes
        continue if node.type isnt "tag"

        node.name = node.name.toLowerCase()
        node.name = node.name.replace(/-/g,"")

        if node.attribs
            if node.attribs["type"]
                node.attribs["type"] = node.attribs["type"].replace /\s+/, ""
                # console.log "fixed type attribute: #{node.attribs["type"]}"

        normalizeElements node.children

    return

#-------------------------------------------------------------------------------
getHttp = (url, callback) ->
    urlParsed = URL.parse(url)
    request   = http.request(urlParsed)

    request.on "response", (response) ->
        body = ""

        response.setEncoding "utf8"

        response.on "data", (chunk) ->
            body += chunk

        response.on "end", ->
            if response.statusCode isnt 200
                err = Error "http status: #{response.statusCode}"
                err.weatherURL = url
                return callback err, body

            callback null, body

        response.on "error", (err) ->
            err.weatherURL = url
            return callback err, body

    request.on "error", (err) ->
        err.weatherURL = url
        return callback err

    request.end()

    return

#-------------------------------------------------------------------------------
# for a function that can take a callback OR return a promise, get a callback
# and the return value of the function (null or the promise) to use internally.
# Hopefully obvious, the callback returned when a promise is being used will
# reject/resolve the promise when the callback is called.
#-------------------------------------------------------------------------------
getCallbackAndResult = (callback) ->
    result = null

    if _.isFunction callback
        return {callback, result}

    deferred = Q.defer()
    result   = deferred.promise

    callback = (err, value) ->
        if err?
            deferred.reject err
        else
            deferred.resolve value

    return {callback, result}

#-------------------------------------------------------------------------------
JS = (object) -> JSON.stringify object
JL = (object) -> JSON.stringify object, null, 4

#-------------------------------------------------------------------------------
if require.main is module
    p = api.getLocations()
    p.then (data) ->
        console.log "locations: #{JL data}"
    p.fail (err) ->
        console.log "locations: error: #{err}"
    p.done()

    p = api.getWeatherByZip("27539")
    p.then (data) ->
        console.log "weather: #{JL data}"
    p.fail (err) ->
        console.log "weather: error: #{err}"
    p.done()

#-------------------------------------------------------------------------------
# Copyright 2014 Patrick Mueller
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
