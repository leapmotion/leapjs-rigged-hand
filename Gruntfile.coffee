module.exports = (grunt) ->

  filename = "leap.rigged-hand-<%= pkg.version %>"

  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    # note that for performance, watch does not minify. be sure to do so before shipping.
    watch: {
      options: {
        livereload: true
        atBegin: true
      }
      coffee: {
        files: ['src/*.coffee', 'examples/*.coffee'],
        tasks: ['default-no-uglify'],
        options: {
          spawn: false,
        },
      },
      js: {
        files: ['src/models/*.js'],
        tasks: ['default-no-uglify'],
        options: {
          spawn: false,
        },
      },
      html: {
        files: ['./*.html'],
        tasks: [],
        options: {
          spawn: false,
        },
      },
      grunt: {
        files: ['Gruntfile.coffee'],
        tasks: ['default-no-uglify']
      }
    },
    coffee:
      build:
        files: [{
          expand: true
          cwd: 'src/'
          src: 'leap.rigged-hand.coffee'
          dest: 'build/'
          rename: (task, path, options)->
            task + filename + '.js'
        },
        {
          expand: true
          cwd: 'examples/'
          src: '*.coffee'
          dest: 'examples/'
          rename: (task, path, options)->
            task + path.replace('.coffee', '.js')
        }]
    concat: {
      build: {
        src: ['src/lib/*.js', 'src/models/hand_models_v1.js', 'build/' + filename + '.js'],
        dest: 'build/' + filename + '.js'
        options: {
          banner: ";(function( window, undefined ){\n\n",
          footer: "\n}( window ));"
        }
      }
    }
    'string-replace': {
      build: {
        files: {
          './': './*.html'
        }
        options:{
            replacements: [
              {
                pattern: /leap.rigged-hand-*\.js/
                replacement: filename + '.js'
              }
            ]
          }
        }
      }
    clean: {
      build: {
        src: ['./build/*']
      }
    }
    uglify: {
      build: {
        src: "build/#{filename}.js"
        dest: "build/#{filename}.min.js"
      }
    }
    usebanner: {
      build: {
        options: {
          banner:    '/*
                    \n * LeapJS Rigged Hand - v<%= pkg.version %> - <%= grunt.template.today(\"yyyy-mm-dd\") %>
                    \n * http://github.com/leapmotion/leapjs-rigged-hand/
                    \n *
                    \n * Copyright <%= grunt.template.today(\"yyyy\") %> LeapMotion, Inc
                    \n *
                    \n * Licensed under the Apache License, Version 2.0 (the "License");
                    \n * you may not use this file except in compliance with the License.
                    \n * You may obtain a copy of the License at
                    \n *
                    \n *     http://www.apache.org/licenses/LICENSE-2.0
                    \n *
                    \n * Unless required by applicable law or agreed to in writing, software
                    \n * distributed under the License is distributed on an "AS IS" BASIS,
                    \n * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                    \n * See the License for the specific language governing permissions and
                    \n * limitations under the License.
                    \n *
                    \n */
                    \n'
        }
        src: ["build/#{filename}.js", "build/#{filename}.min.js"]
      }
    }
    connect: {
      server: {
        options: {
          port: 8000
        }
      }
    }

  require('load-grunt-tasks')(grunt);


  grunt.registerTask('serve', [
    'default-no-uglify',
    'connect',
    'watch',
  ]);

  grunt.registerTask('default-no-uglify', [
    'clean',
    'coffee',
    'concat',
    'string-replace'
  ]);

  grunt.registerTask('default', [
    'clean',
    'coffee',
    'concat',
    'string-replace',
    'uglify',
    'usebanner'
  ]);
