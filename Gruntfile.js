// Check if Newer works correct
// CORS setting
// Set images paths to cdn in less and source files
 
// Versioning css cloudfront grunt
// Split the tasks in to different files

module.exports = function (grunt) {
  grunt.initConfig({
    dir: {
      repoPublic: './current/public',
      cdnPublic: './shared/public',
      staticLess: '/css/front_end',
      staticJs: '/js/front_end'
    },
    variables: {
      locales: ['at', 'au', 'be', 'br', 'ca', 'ch', 'de', 'dk', 'es', 'fi', 'fr', 'id', 'in', 'it', 'jp', 'my', 'no', 'pl', 'pt', 'se', 'sg', 'tr', 'uk', 'us', 'za', 'kr', 'ar', 'ru', 'hk', 'sk', 'nz', 'cl', 'ie', 'mx', 'cn'],

    },
    pkg: grunt.file.readJSON('package.json'),
    concat: {
      options: {
        separator: ';'
      },
      dist: {
        src: '<%= dir.repoPublic %><%= dir.staticJs %>/**/*.js',
        dest: '<%= dir.repoPublic %><%= dir.staticJs %>/all.js'
      },
    },
    uglify: {
      options: {
        banner: '/*! All needed Javascript <%= grunt.template.today("dd-mm-yyyy") %> */\n'
      },
      dist: {
        src: '<%= dir.repoPublic %><%= dir.staticJs %>/all.js',
        dest: '<%= dir.cdnPublic %><%= dir.staticJs %>/all.min.js'
      },
    },
    less: {
      production: {
        options: {
          paths: ["<%= dir.repoPublic %><%= dir.staticLess %>"],
          cleancss: true,
        },
        files: {
          "<%= dir.cdnPublic %><%= dir.staticLess %>/all.min.css": "<%= dir.repoPublic %><%= dir.staticLess %>/all.less"
        }
      }
    },
    imagemin: {
      png: {
        options: {
          optimizationLevel: 7
        },
        files: [
          {
            expand: true,
            cwd: '<%= dir.repoPublic %>',
            src: ['**/*.png'],
            dest: '<%= dir.cdnPublic %>',
            ext: '.png'
          }
        ]
      },
      jpg: {
        options: {
          progressive: true
        },
        files: [
          {
            expand: true,
            cwd: '<%= dir.repoPublic %>',
            src: ['**/*.jpg'],
            dest: '<%= dir.cdnPublic %>',
            ext: '.jpg'
          }
        ]
      }
    },
    watch: {
      files: ['<%= dir.repoPublic %><%= dir.staticJs %>/**/*.js'],
      tasks: ['default']
    },
    newer: {
      options: {
        cache: '<%= dir.cdnPublic %>/cache'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-imagemin');
  grunt.loadNpmTasks('grunt-newer');

  grunt.registerTask('css', ['newer:less:production']);
  grunt.registerTask('imageoptimisation', ['newer:imagemin']);

  grunt.registerTask('default', 'Contactenate all flipit stuff', function () {
    var concat = grunt.config.get('concat') || {};
    var uglify = grunt.config.get('uglify') || {};
    var repoPublicDir = grunt.config.get('dir.repoPublic') || {};
    var cdnPublicDir = grunt.config.get('dir.cdnPublic') || {};
    var jsDir = grunt.config.get('dir.staticJs') || {};
    var locales = grunt.config.get('variables.locales') || {};

    locales.forEach(function (locale) {

      // Generating Concatination settings
      concat[locale] = {
        src: [ repoPublicDir + jsDir + '/**/*.js'],
        dest: repoPublicDir + '/' + locale + jsDir + '/all.js'
      };
      grunt.config.set('concat', concat);

      // Generating Uglify settings
      uglify[locale] = {
        src: repoPublicDir + '/' + locale + jsDir + '/all.js',
        dest: cdnPublicDir + '/' + locale + jsDir + '/all.min.js'
      };
      grunt.config.set('uglify', uglify);

    });

    // Running tasks
    grunt.task.run('css');
    grunt.task.run('concat');
    grunt.task.run('uglify');

  });
};






