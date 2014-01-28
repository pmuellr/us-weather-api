# Licensed under the Apache License. See footer for details.

_      = require "underscore"
expect = require "expect.js"
semver = require "semver"

uws = require ".."

#-------------------------------------------------------------------------------
describe "getWeatherByZip", ->

    #----------------------------------
    it "getWeatherByZip callback", (done) ->
        uws.getWeatherByZip "27539", (err, data) ->
            expect(err).to.not.be.ok()

            checkData data

            done()

    #----------------------------------
    it "getWeatherByZip promise ", (done) ->
        p = uws.getWeatherByZip "27539"

        p.then (data) -> checkData data
        p.fail (err) -> expect().fail(err)
        p.finally -> done()
        p.done()

#-------------------------------------------------------------------------------
checkData = (data) ->
    expect(_.isObject data).to.be.ok()

    expect(_.isDate new Date(data.date)).to.be.ok()
    expect(_.isNumber data.lat).to.be.ok()
    expect(_.isNumber data.lon).to.be.ok()
    expect(_.isObject data.forecast).to.be.ok()

    for date, values of data.forecast
        expect(_.isDate new Date(date)).to.be.ok()

        for name, value of values
            expect(_.isString name).to.be.ok()
            expect(_.isNumber value).to.be.ok()

    return

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
