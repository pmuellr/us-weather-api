# Licensed under the Apache License. See footer for details.

_      = require "underscore"
expect = require "expect.js"
semver = require "semver"

uws = require ".."

#-------------------------------------------------------------------------------
describe "getLocations", ->

    #----------------------------------
    it "getLocations callback", (done) ->
        uws.getLocations (err, data) ->
            expect(err).to.not.be.ok()

            checkData data

            done()

    #----------------------------------
    it "getLocations promise ", (done) ->
        p = uws.getLocations()

        p.then (data) -> checkData data
        p.fail (err) -> expect().fail(err)
        p.finally -> done()
        p.done()

#-------------------------------------------------------------------------------
checkData = (data) ->
    expect(_.isArray data).to.be.ok()

    for datum in data
        {lat, lon, city, state} = datum

        expect( _.isNumber lat   ).to.be.ok()
        expect( _.isNumber lon   ).to.be.ok()
        expect( _.isString city  ).to.be.ok()
        expect( _.isString state ).to.be.ok()

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
