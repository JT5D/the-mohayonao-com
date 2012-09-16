'use strict'

fs     = require 'fs'
path   = require 'path'
coffee = require 'coffee-script'
uglify = require 'uglify-js'
less   = require 'less'
lessParser = new less.Parser

rootpath = "#{__dirname}/static"

dateFormat = (date)->
    hh = ('00' + date.getHours()  ).substr -2
    mm = ('00' + date.getMinutes()).substr -2
    ss = ('00' + date.getSeconds()).substr -2
    "#{hh}:#{mm}:#{ss}"

compilers =
    coffee:
        ext : 'js'
        exec: (src, callbcak)->
            try
                src = coffee.compile src
            catch exp
                return callbcak err:"#{exp.message}"
            ast = uglify.parser.parse src
            ast = uglify.uglify.ast_mangle ast, {toplevel:true}
            ast = uglify.uglify.ast_squeeze ast
            src = uglify.uglify.gen_code ast
            callbcak src:src, ext:'js'

    less:
        ext : 'css'
        exec: (src, callback)->
            lessParser.parse src, (err, tree)->
                if err
                    return callback err:"#{err.type} error on line #{err.line}: #{err.message}"
                callback src:tree.toCSS(compress:true).replace(/\n/, ''), 'css'


class DirWatcher
    @map = {}
    constructor: (dirpath)->
        if DirWatcher.map[dirpath] then return
        DirWatcher.map[dirpath] = @

        @dirpath = dirpath
        @watcher = fs.watch dirpath, (e)=>
            if path.existsSync dirpath then @crawl() else @close()
        @dirpath = dirpath
        @list    = []
        @crawl()

    crawl: ->
        for name in fs.readdirSync @dirpath
            filepath = "#{@dirpath}/#{name}"
            st = fs.lstatSync filepath
            if st.isDirectory()
                new DirWatcher  filepath
            else
                w = new FileWatcher filepath
                if w.filename then @list.push w

    close: ->
        @list.forEach (x)-> x.close()
        @list = []
        @watcher.close()
        delete DirWatcher[@dirpath]
        console.log "[#{dateFormat new Date}] #{@dirpath}: DELETE"


class FileWatcher
    @map = {}
    constructor: (filepath)->
        if filepath.indexOf('#') != -1 or filepath.indexOf('~') != -1
            return

        ext = (/\.([^.]+)$/.exec filepath)?[1]
        if not compilers[ext] then return

        if FileWatcher.map[filepath] then return
        FileWatcher.map[filepath] = @

        compiler = compilers[ext]
        @filename = filepath.substr rootpath.length
        @src_ext      = ext
        @src_filepath = filepath
        @dst_ext      = compiler.ext
        @dst_filepath = filepath.substr(0, filepath.lastIndexOf @src_ext) + @dst_ext
        compile = =>
            src = fs.readFileSync filepath, 'utf-8'
            if src is compile.saved then return
            compiler.exec src, (res)=>
                compile.saved = src
                msg = ''
                if not res.err
                    fs.writeFile @dst_filepath, res.src
                    msg = 'ok'
                else msg = res.err
                console.log "[#{dateFormat new Date}] #{@filename}: #{msg}"
        @watcher = fs.watch filepath, (e)=>
            if path.existsSync filepath then compile() else @close()
        compile()

    close: ->
        @watcher.close()
        delete FileWatcher[@src_filepath]
        if path.existsSync @dst_filepath
            fs.unlink @dst_filepath
        console.log "[#{dateFormat new Date}] #{@filename}: DELETE"

new DirWatcher rootpath
