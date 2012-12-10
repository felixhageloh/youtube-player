{spawn, exec} = require 'child_process'

runCommand = (name, args, callback) ->
  proc =           spawn name, args
  proc.stderr.on   'data', (buffer) -> process.stderr.write buffer.toString()
  proc.stdout.on   'data', (buffer) -> process.stdout.write buffer.toString()
  proc.on          'exit', (status) -> if status is 0 then callback?() else process.exit(1) 

task 'watch', 'Watch source files and build JS & CSS to lib', ->
  runCommand 'coffee', ['-w', '-c', '-o', 'lib/', 'src/']
  runCommand 'stylus', ['-w', 'src/', '-o', 'lib/']

task 'build', 'build and minify JS & CSS to dist', ->
  runCommand 'coffee', ['-c', '-o', 'dist/', 'src/'], ->
    runCommand 'uglifyjs', ['-o', 'dist/player.js', 'dist/player.js']
  
  runCommand 'stylus', ['-c', 'src/', '-o', 'dist/']