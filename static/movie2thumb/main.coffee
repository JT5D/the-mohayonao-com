$ ->
    'use strict'

    THUMB_SIZE = 80

    createObjectURL = (window.URL or window.webkitURL)?.createObjectURL

    $(window).on 'dragover', ->
        false

    $(window).on 'drop', (e)->
        if app and createObjectURL
            app.preview e.originalEvent.dataTransfer.files[0], =>
                app.getImage()
        false

    resizeContainer = (w, h)->
        $('#container1').width(w)
        $('#container2').width(w).height(h)

    if window.innerWidth < 800 or window.innerWidth < 600
        resizeContainer 640, 480
    else if window.innerWidth < 980 or window.innerHeight < 760
        resizeContainer 800, 600

    unless createObjectURL then return

    $('#shuffle').on 'change', ->
        app.shuffle = !!$(this).attr('checked')

    shuffle = (array)->
        i = array.length
        while i
            j = Math.floor(Math.random() * i--)
            [ array[i], array[j] ] = [ array[j], array[i] ]
        array

    class App
        constructor: (target)->
            @target = target
            @video  = null
            @count  = 0
            @width  = $(target).width()
            @height = $(target).height()
            canvas  = document.createElement 'canvas'
            canvas.width  = @width
            canvas.height = @height
            $(canvas).width (@width )
            $(canvas).height(@height)
            @canvas  = canvas
            @context = canvas.getContext '2d'
            @shuffle = false

        preview: (file, callback)->
            video = document.createElement 'video'
            type = file.type.substr 0, 5
            @video = null
            @list  = []
            if type is 'video' and video.canPlayType file.type
                $(video).on 'loadeddata', =>
                    @initCanvas()
                    @seek callback
                $(video).on 'seeked', =>
                    @fetchAndDraw =>
                        @seek callback
                video.type = file.type
                video.src  = createObjectURL file
                @video = video
            @count = 0

        getImage: ->
            image = new Image
            image.onload = =>
                $(@target).empty().append image
            image.src = @canvas.toDataURL 'image/jpeg'

        initCanvas: ->
            $(@target).empty().append @canvas

            [vw, vh] = [@video.videoWidth, @video.videoHeight]
            [cw, ch] = [THUMB_SIZE, THUMB_SIZE]
            if vw > vh
                h = cw * (vh / vw)
                [@dw, @dh] = [cw, h]
            else
                w = ch * (vw / vh)
                [@dw, @dh] = [w, ch]
            @dw |= 0
            @dh |= 0
            @lenX = Math.ceil(@width  / @dw)
            @lenY = Math.ceil(@height / @dh)
            @context.clearRect 0, 0, cw, ch
            [@sw, @sh] = [vw, vh]

            @list = for i in [0...@lenX * @lenY]
                @video.duration * (i / (@lenX * @lenY))
            if @shuffle then @list = shuffle @list

        seek: (callback)->
            time = @list.shift()
            if not @video or time is undefined then return callback?()
            @video.currentTime = time

        fetchAndDraw: (callback)->
            x = (@count % @lenX)
            y = (@count / @lenX)|0
            @context.drawImage @video, 0, 0, @sw, @sh, @dw * x, @dh * y, @dw, @dh
            @count += 1
            callback()

    app = new App(document.getElementById 'container2')
