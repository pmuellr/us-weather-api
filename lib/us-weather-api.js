// Generated by CoffeeScript 1.6.3
(function() {
  var DataNameMap, DataSets, JL, JS, Q, URL, URLprefix, WeatherParms, api, findElement, findElements, getCallbackAndResult, getDate, getHttp, getParameterData, getText, getTimeLayouts, getTimes, handle_getLocations, handle_getWeather, htmlParser, http, normalizeElements, p, parseXML, pkg, select, soupSelect, util, valueParser, valueParserFloat, _;

  URL = require("url");

  http = require("http");

  util = require("util");

  Q = require("q");

  _ = require("underscore");

  htmlParser = require("htmlparser");

  soupSelect = require("soupselect");

  select = soupSelect.select;

  pkg = require("../package.json");

  api = exports;

  URLprefix = "http://graphical.weather.gov/xml/sample_products/browser_interface/ndfdXMLclient.php";

  DataNameMap = {
    "Temperature": "temp",
    "Dew Point Temperature": "dew",
    "Apparent Temperature": "appt",
    "12 Hourly Probability of Precipitation": "pop12",
    "Liquid Precipitation Amount": "qpf",
    "Snow Amount": "snow",
    "Ice Accumulation": "iceaccum",
    "Cloud Cover Amount": "sky",
    "Relative Humidity": "rh"
  };

  DataSets = [['temperature[type="hourly"]', parseInt], ['temperature[type="dewpoint"]', parseInt], ['temperature[type="apparent"]', parseInt], ['precipitation[type="liquid"]', parseFloat], ['precipitation[type="snow"]', parseFloat], ['precipitation[type="ice"]', parseFloat], ['cloudamount', parseInt], ['probabilityofprecipitation', parseInt], ['humidity', parseInt]];

  WeatherParms = _.values(DataNameMap);

  WeatherParms = _.map(WeatherParms, function(parm) {
    return "" + parm + "=" + parm;
  });

  WeatherParms = WeatherParms.join("&");

  api.version = pkg.version;

  api.getLocations = function(callback) {
    var result, url, _ref;
    _ref = getCallbackAndResult(callback), callback = _ref.callback, result = _ref.result;
    url = "" + URLprefix + "?listCitiesLevel=1234";
    getHttp(url, function(err, body) {
      if (err != null) {
        err.weatherURL = url;
        callback(err);
        return result;
      }
      try {
        return handle_getLocations(body, callback);
      } catch (_error) {
        err = _error;
        err.weatherURL = url;
        callback(err);
        return result;
      }
    });
    return result;
  };

  api.getWeatherByZip = function(zipcode, callback) {
    var parsedZipcode, result, url, _ref;
    _ref = getCallbackAndResult(callback), callback = _ref.callback, result = _ref.result;
    parsedZipcode = parseInt("" + zipcode);
    if (isNaN(parsedZipcode)) {
      callback(Error("zipcode value is not an integer"));
      return result;
    }
    url = "" + URLprefix + "?product=time-series&zipCodeList=" + zipcode;
    getHttp(url, function(err, body) {
      if (err != null) {
        err.weatherURL = url;
        callback(err);
        return result;
      }
      try {
        return handle_getWeather(body, callback);
      } catch (_error) {
        err = _error;
        err.weatherURL = url;
        callback(err);
        return result;
      }
    });
    return result;
  };

  api.getWeatherByGeo = function(lat, lon, callback) {
    var parsedLat, parsedLon, result, url, _ref;
    _ref = getCallbackAndResult(callback), callback = _ref.callback, result = _ref.result;
    parsedLat = parseFloat("" + lat);
    if (isNaN(parsedLat)) {
      callback(Error("latitude value is not a number"));
      return result;
    }
    parsedLon = parseFloat("" + lon);
    if (isNaN(parsedLon)) {
      callback(Error("longitude value is not a number"));
      return result;
    }
    url = "" + URLprefix + "?product=time-series&listLatLon=" + lat + "," + lon + "&" + WeatherParms;
    getHttp(url, function(err, body) {
      if (err != null) {
        err.weatherURL = url;
        callback(err);
        return result;
      }
      try {
        return handle_getWeather(body, callback);
      } catch (_error) {
        err = _error;
        err.weatherURL = url;
        callback(err);
        return result;
      }
    });
    return result;
  };

  handle_getLocations = function(xml, callback) {
    var city, cn, cnList, dom, i, lat, ll, llList, lon, result, state, _i, _ref, _ref1, _ref2;
    dom = parseXML(xml);
    llList = getText(select(dom, "latlonlist"));
    cnList = getText(select(dom, "citynamelist"));
    llList = llList.split(" ");
    cnList = cnList.split("|");
    result = [];
    for (i = _i = 0, _ref = llList.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      ll = llList[i];
      cn = cnList[i];
      _ref1 = ll.split(","), lat = _ref1[0], lon = _ref1[1];
      _ref2 = cn.split(","), city = _ref2[0], state = _ref2[1];
      lat = parseFloat(lat);
      lon = parseFloat(lon);
      result.push({
        lat: lat,
        lon: lon,
        city: city,
        state: state
      });
    }
    return callback(null, result);
  };

  handle_getWeather = function(xml, callback) {
    var dom, forecast, name, parser, point, result, selector, time, timeLayouts, times, value, values, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
    result = {};
    dom = parseXML(xml);
    result.date = getDate(select(dom, "creationdate"));
    point = select(dom, "data location point")[0];
    result.lat = parseFloat(point.attribs.latitude);
    result.lon = parseFloat(point.attribs.longitude);
    timeLayouts = getTimeLayouts(dom);
    times = getTimes(timeLayouts);
    result.forecast = forecast = {};
    for (_i = 0, _len = times.length; _i < _len; _i++) {
      time = times[_i];
      forecast[time] = {};
    }
    for (_j = 0, _len1 = DataSets.length; _j < _len1; _j++) {
      _ref = DataSets[_j], selector = _ref[0], parser = _ref[1];
      _ref1 = getParameterData(dom, timeLayouts, selector, parser), name = _ref1.name, values = _ref1.values;
      if (name == null) {
        continue;
      }
      name = DataNameMap[name];
      for (_k = 0, _len2 = values.length; _k < _len2; _k++) {
        _ref2 = values[_k], time = _ref2.time, value = _ref2.value;
        forecast[time][name] = value;
      }
    }
    callback(null, result);
  };

  getParameterData = function(dom, timeLayouts, elementName, parser) {
    var elements, i, layout, len, name, rawValues, time, value, values, _i;
    elements = select(dom, "data parameters " + elementName);
    if (elements[0] == null) {
      return {};
    }
    layout = elements[0].attribs["time-layout"];
    if (layout == null) {
      return {};
    }
    layout = timeLayouts[layout];
    if (layout == null) {
      return {};
    }
    name = getText(select(elements, "name"));
    values = select(elements, "value");
    if ((name == null) || (values == null)) {
      return {};
    }
    rawValues = _.map(values, function(value) {
      return valueParser(value, parser);
    });
    len = Math.min(values.length, layout.length);
    values = [];
    for (i = _i = 0; 0 <= len ? _i < len : _i > len; i = 0 <= len ? ++_i : --_i) {
      time = layout[i];
      value = rawValues[i];
      values.push({
        time: time,
        value: value
      });
    }
    return {
      name: name,
      values: values
    };
  };

  valueParser = function(dom, fn) {
    var text, value;
    text = getText(dom);
    if (fn === parseInt) {
      value = parseInt(text, 10);
    } else {
      value = parseFloat(text);
    }
    if (isNaN(value)) {
      value = 0;
    }
    return value;
  };

  valueParserFloat = function(dom) {
    var text, value;
    text = getText(dom);
    value = parseFloat(text);
    if (isNaN(value)) {
      value = 0.0;
    }
    return value;
  };

  getTimeLayouts = function(dom) {
    var key, layoutElement, layoutElements, result, timeElements, times, _i, _len;
    result = {};
    layoutElements = select(dom, "timelayout");
    for (_i = 0, _len = layoutElements.length; _i < _len; _i++) {
      layoutElement = layoutElements[_i];
      key = getText(select(layoutElement, "layoutkey"));
      timeElements = select(layoutElement, "startvalidtime");
      times = _.map(timeElements, function(timeElement) {
        return getDate(timeElement);
      });
      result[key] = times;
    }
    return result;
  };

  getTimes = function(timeLayouts) {
    var layout, time, timeKeys, times, _i, _len;
    timeKeys = {};
    for (layout in timeLayouts) {
      times = timeLayouts[layout];
      for (_i = 0, _len = times.length; _i < _len; _i++) {
        time = times[_i];
        timeKeys[time] = time;
      }
    }
    timeKeys = _.keys(timeKeys);
    timeKeys = timeKeys.sort();
    return timeKeys;
  };

  findElements = function(nodes, tag, result) {
    var node, _i, _len;
    result = result || [];
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      if (node.type === "tag") {
        if (node.name === tag) {
          result.push(node);
        }
      }
      if (node.children != null) {
        findElements(node.children, tag, result);
      }
    }
    return result;
  };

  findElement = function(nodes, tag, result) {
    var elements;
    elements = findElements(nodes, tag);
    return elements[0];
  };

  getDate = function(nodes) {
    var date, text;
    text = getText(nodes);
    date = new Date(text);
    return date.toISOString().replace("T", " ");
  };

  getText = function(nodes, result) {
    var node, _i, _len;
    if (!_.isArray(nodes)) {
      nodes = [nodes];
    }
    result = result || "";
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      if (node.type === "text") {
        result += node.data;
      }
      if (node.children != null) {
        result = getText(node.children, result);
      }
    }
    return result;
  };

  parseXML = function(body) {
    var handler, parser, result;
    result = null;
    handler = new htmlParser.DefaultHandler(function(err, nodes) {
      if (err == null) {
        return result = nodes;
      }
    });
    parser = new htmlParser.Parser(handler);
    parser.parseComplete(body);
    normalizeElements(result);
    return result;
  };

  normalizeElements = function(nodes) {
    var node, _i, _len;
    if (nodes == null) {
      return;
    }
    if (!_.isArray(nodes)) {
      nodes = [nodes];
    }
    for (_i = 0, _len = nodes.length; _i < _len; _i++) {
      node = nodes[_i];
      if (node.type !== "tag") {
        continue;
      }
      node.name = node.name.toLowerCase();
      node.name = node.name.replace(/-/g, "");
      if (node.attribs) {
        if (node.attribs["type"]) {
          node.attribs["type"] = node.attribs["type"].replace(/\s+/, "");
        }
      }
      normalizeElements(node.children);
    }
  };

  getHttp = function(url, callback) {
    var request, urlParsed;
    urlParsed = URL.parse(url);
    request = http.request(urlParsed);
    request.on("response", function(response) {
      var body;
      body = "";
      response.setEncoding("utf8");
      response.on("data", function(chunk) {
        return body += chunk;
      });
      response.on("end", function() {
        var err;
        if (response.statusCode !== 200) {
          err = Error("http status: " + response.statusCode);
          err.weatherURL = url;
          return callback(err, body);
        }
        return callback(null, body);
      });
      return response.on("error", function(err) {
        err.weatherURL = url;
        return callback(err, body);
      });
    });
    request.on("error", function(err) {
      err.weatherURL = url;
      return callback(err);
    });
    request.end();
  };

  getCallbackAndResult = function(callback) {
    var deferred, result;
    result = null;
    if (_.isFunction(callback)) {
      return {
        callback: callback,
        result: result
      };
    }
    deferred = Q.defer();
    result = deferred.promise;
    callback = function(err, value) {
      if (err != null) {
        return deferred.reject(err);
      } else {
        return deferred.resolve(value);
      }
    };
    return {
      callback: callback,
      result: result
    };
  };

  JS = function(object) {
    return JSON.stringify(object);
  };

  JL = function(object) {
    return JSON.stringify(object, null, 4);
  };

  if (require.main === module) {
    p = api.getLocations();
    p.then(function(data) {
      return console.log("locations: " + (JL(data)));
    });
    p.fail(function(err) {
      return console.log("locations: error: " + err);
    });
    p.done();
    p = api.getWeatherByZip("27539");
    p.then(function(data) {
      return console.log("weather: " + (JL(data)));
    });
    p.fail(function(err) {
      return console.log("weather: error: " + err);
    });
    p.done();
  }

}).call(this);