# Licensed under the Apache License. See footer for details.

fs   = require "fs"
path = require "path"

#-------------------------------------------------------------------------------

tasks = defineTasks exports,
    watch : "source file changes -> build/test"
    build : "build the code"
    test:   "test the code"

#-------------------------------------------------------------------------------

mkdir "-p", "tmp"

#-------------------------------------------------------------------------------

tasks.build = ->
    cleanDir "lib"

    log "starting build"
    coffee "--output lib lib-src"

#-------------------------------------------------------------------------------

tasks.test = ->
    tests = "tests/test-*.coffee"

    options =
        ui:         "bdd"
        reporter:   "spec"
        compilers:  "coffee:coffee-script"

    options = for key, val of options
        "--#{key} #{val}"

    options = options.join " "

    log "starting tests"
    mocha "#{options} #{tests}"

#-------------------------------------------------------------------------------

tasks.watch = ->
    buildNtest()

    watchFiles "lib-src/**/* tests/**/*" :->
        buildNtest()

    watchFiles "jbuild.coffee" :->
        log "jbuild file changed; exiting"
        process.exit 0

#-------------------------------------------------------------------------------

buildNtest = ->
    tasks.build()
    tasks.test()

#-------------------------------------------------------------------------------

cleanDir = (dir) ->
    mkdir "-p", dir
    rm "-rf", "#{dir}/*"

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
