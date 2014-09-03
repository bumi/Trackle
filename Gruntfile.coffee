
module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    config:
      dest: "Mole.app/Contents/Resources/app.nw/dist"

  # -----------------------------------------------------------------

    watch:
      coffee:
        files: ['src/**/*.coffee']
        tasks: ['coffee:compile']

      cson:
        files: ['src/**/*.cson']
        tasks: ['cson:compile']

      static:
        files: ['src/**/*.html', 'src/config.cson']
        tasks: ['copy:static']

      sass:
        files: ['src/**/*.scss']
        tasks: ['sass:compile']

      templates:
        files: ['src/templates/**/*.tpl']
        tasks: ['jst:compile']

      vendor:
        files: ['vendor/**/*.js']
        tasks: ['uglify:vendor']

  # -----------------------------------------------------------------

    coffee:
      compile:
        options:
          join: true
        files:
          '<%= config.dest %>/app.js': [
            'src/lib/*.coffee'
            'src/models/*.coffee'
            'src/collections/*.coffee'
            'src/regions/*.coffee'
            'src/layouts/*.coffee'
            'src/app.coffee'
            'src/modules/*.coffee'
            'src/behaviors/*.coffee'
            'src/init.coffee'
          ]

  # -----------------------------------------------------------------
    cson:
      glob_to_multiple:
        src: ['src/config.cson' ]
        dest: '<%= config.dest %>/config.json'
        ext: '.json'

  # -----------------------------------------------------------------

    copy:
      static:
        files: [
          { src: ['src/index.html'], dest: '<%= config.dest %>/index.html', filter: 'isFile' }
        ]

  # -----------------------------------------------------------------

    sass:
      compile:
        options:
          style: 'expanded'
        files:
          '<%= config.dest %>/app.css': 'src/app.scss'

  # -----------------------------------------------------------------

    jst:
      compile:
        namespace: "JST"
        options:
          processContent: (src) -> src.replace(/(^\s+|\s+$|\n)/gm, '')
          processName: (filename) -> filename.replace("src/templates/", "").replace(".tpl", "")
          templateSettings:
            interpolate : /\{\{(.+?)\}\}/g
            variable: 'm'
        files:
          "<%= config.dest %>/templates.js": ["src/templates/**/*.tpl"]

  # -----------------------------------------------------------------

    uglify:
      vendor:
        options:
          mangle: false
          beautify: true
        files:
          '<%= config.dest %>/vendor.js': [
            "vendor/jquery-1.10.2.min.js"
            "vendor/jquery.transit.min.js"
            "vendor/underscore-min.js"
            "vendor/backbone-min.js"
            "vendor/backbone.stickit.js"
            "vendor/backbone.marionette.min.js"
            "vendor/moment-with-langs.min.js"
            "vendor/moment-range.js"
            "vendor/drop.js"
            "vendor/select2.js"
            "vendor/jquery.panelSnap.js"
            "vendor/raygun.min.js"
            "vendor/md5.js"
            "vendor/kinetic-v5.1.0.min.js"
          ]

  # -----------------------------------------------------------------

  for module, _ of grunt.config.data.pkg.devDependencies
    grunt.loadNpmTasks module

  # -----------------------------------------------------------------

  grunt.registerTask 'default', ['dev']

  # -----------------------------------------------------------------

  grunt.registerTask 'startup', ['coffee:compile', 'cson', 'copy:static', 'sass:compile', 'jst:compile', 'uglify:vendor']
  grunt.registerTask 'dev', ['startup', 'watch']
  grunt.registerTask 'server', ['connect:server:keepalive']
