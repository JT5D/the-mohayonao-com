$ ->
    'use strict'

    SAMPLERATE = 8000
    BUFFER_SIZE = 1 << 16
    BUFFER_MASK = BUFFER_SIZE - 1

    MutekiTimer.use()

    processor = new class OneLinerProcessor
        constructor: ->
            @buffer = new Uint8Array(BUFFER_SIZE)
            @rindex = @windex = @timerId = 0
            @acceptTimerId = 0

        onmessage = (e)->
            if e.data instanceof Array
                stream = e.data
                for i in [0...stream.length]
                    @buffer[@windex++ & BUFFER_MASK] = stream[i]
            else switch e.data
                when 'error'
                    @onerror?()
                when 'accept'
                    @accept = true
                    @onaccept?()

        start: ->
            if @timerId != 0
                clearInterval @timerId = 0
            @timerId = setInterval =>
                if @windex - 4096 < @rindex
                    @worker.postMessage 0
            , 100

        stop: ->
            if @timerId != 0
                clearInterval @timerId = 0
            @timerId = 0

        fetch: ->
            @buffer[@rindex++ & BUFFER_MASK]

        setFunction: (@func)->
            @worker = new Worker('/one-liner-music/worker.js')
            @worker.onmessage = onmessage.bind @

            @accept = false
            @worker.postMessage @func

            if @acceptTimerId
                clearTimeout @acceptTimerId
            @acceptTimerId = setTimeout =>
                if not @accept
                    @onerror?()
            , 500

    class Player
        play : ->
            @isPlaying = true
        pause: ->
            @isPlaying = false


    class WebKitPlayer extends Player
        @isEnabled: ->
            webkitAudioContext?

        constructor: (@processor)->
            @context = new webkitAudioContext()
            @samples = 0
            @dt = SAMPLERATE / @context.sampleRate
            @value = 0

        play: ->
            @isPlaying = true
            @bufSrc = @context.createBufferSource()
            @jsNode = @context.createJavaScriptNode 4096, 1, 1
            @jsNode.onaudioprocess = (e)=>
                output = e.outputBuffer.getChannelData 0
                for i in [0...output.length]
                    if @samples <= 0
                        @value = @processor.fetch()
                        @samples += 1
                    @samples -= @dt
                    output[i] = @value / 256
            @bufSrc.connect @jsNode
            @jsNode.connect @context.destination
            @bufSrc.noteOn 0
            @processor.start()

        pause: ->
            @isPlaying = false
            @bufSrc.disconnect()
            @jsNode.disconnect()
            @processor.stop()


    class MozPlayer extends Player
        @isEnabled: ->
            a = new Audio()
            typeof a.mozSetup is 'function'

        SAMPLES = 1024

        constructor: (@processor)->
            @timerId = 0

        play: ->
            @isPlaying = true
            audio = new Audio()
            audio.mozSetup 1, SAMPLERATE
            if @timerId != 0
                clearInterval @timerId
            written = 0
            stream = new Float32Array(SAMPLES)
            @timerId = setInterval =>
                offset = audio.mozCurrentSampleOffset()
                if offset > 0 and written > offset + 16384
                    return
                for i in [0...stream.length]
                    stream[i] = @processor.fetch() / 256
                audio.mozWriteAudio stream
                @written += i
            , SAMPLES / SAMPLERATE * 1000
            @processor.start()

        pause: ->
            @isPlaying = false
            if @timerId != 0
                clearInterval @timerId
            @processor.stop()

    class OperaPlayer extends Player
        @isEnabled: ->
            /opera/i.test navigator.userAgent

        SAMPLES = 4096

        WAVEHEADER = do ->
            samplerate = SAMPLERATE
            channel = 1
            samples = SAMPLES
            bits    = 1 # 1=8bit 2=16bit
            l1 = (samples * channel * bits) - 8
            l2 = l1 - 36
            String.fromCharCode(
                0x52, 0x49, 0x46, 0x46 # 'RIFF'
                (l1 >>  0) & 0xff,
                (l1 >>  8) & 0xff,
                (l1 >> 16) & 0xff,
                (l1 >> 24) & 0xff,
                0x57, 0x41, 0x56, 0x45, # 'WAVE'
                0x66, 0x6D, 0x74, 0x20, # 'fmt '
                0x10, 0x00, 0x00, 0x00, # byte length
                0x01, 0x00,    # linear pcm
                channel, 0x00, # channel
                (samplerate >>  0) & 0xFF,
                (samplerate >>  8) & 0xFF,
                (samplerate >> 16) & 0xFF,
                (samplerate >> 24) & 0xFF,
                ((samplerate * channel * bits) >> 0) & 0xFF,
                ((samplerate * channel * bits) >> 8) & 0xFF,
                ((samplerate * channel * bits) >> 16) & 0xFF,
                ((samplerate * channel * bits) >> 24) & 0xFF,
                bits * channel, 0x00,   # block size
                8 * bits, 0x00,      # bit
                0x64, 0x61, 0x74, 0x61, # 'data'
                (l2 >>  0) & 0xFF,
                (l2 >>  8) & 0xFF,
                (l2 >> 16) & 0xFF,
                (l2 >> 24) & 0xFF
            )

        constructor: (@processor)->
            @timerId = 0

        play: ->
            @isPlaying = true
            if @timerId != 0
                clearInterval @timerId
            @audio = new Audio()
            @timerId = setInterval =>
                @audio.play()
                wave = WAVEHEADER
                for i in [0...SAMPLES]
                    wave += String.fromCharCode @processor.fetch()
                @audio = new Audio("data:audio/wav;base64,#{btoa(wave)}")
            , SAMPLES / SAMPLERATE * 1000
            @processor.start()

        pause: ->
            @isPlaying = false
            if @timerId != 0
                clearInterval @timerId
            @processor.stop()

    player = do ->
        if WebKitPlayer.isEnabled()
            return new WebKitPlayer(processor)
        if MozPlayer.isEnabled()
            return new MozPlayer(processor)
        if OperaPlayer.isEnabled()
            return new OperaPlayer(processor)
        new Player(processor)

    $('#play').on 'click', ->
        if player.isPlaying
            player.pause()
            $(@).css color:'black'
        else
            player.play()
            $(@).css color:'red'


    $func = $('#func')
    elem_map = {}
    init_history = [
        '(t>>4)&((t<<5)|(Math.sin(t)*3000))'
        't<<(t&7)|(t*(t/500)*0.25)'

        '(t&(t>>10))*(t>>11)&(15<<(t>>16))|t*(t+12)>>(t>>14)&13'

        '(t<<1)/(~t&(1<<(t&15)))'

        '(t*5&t>>7)|(t*3&t>>10)'
        't*((t>>12|t>>8)&63&t>>4)'
    ]
    history = JSON.parse(localStorage.getItem('history')) or init_history
    do ->
        list = history.slice(0)
        list.reverse()
        for h in list
            elem_map[h] = $('<li>').text(h)
            $('#history').after elem_map[h]

    commit = ->
        func = $func.css(color:'black').val()
        processor.setFunction func

    $func.on 'keyup', (e)->
        if e.keyCode is 13 then commit()
    processor.onerror = ->
        $func.css(color:'red')
    processor.onaccept = ->
        func = processor.func
        isExists = false
        for h, i in history
            if h is func
                isExists = true
                history.splice i, 1
                break
        if not isExists
            elem_map[func] = $('<li>').text(func)
        else
            elem_map[func].remove()
        $('#history').after elem_map[func]
        history.unshift func
        history = history.slice 0, 25
        localStorage.setItem 'history', JSON.stringify(history)

    $('#tweet').on 'click', ->
        w = 550
        h = 250
        x = Math.round screen.width  * 0.5 - w * 0.5
        y = Math.round screen.height * 0.5 - h * 0.5

        baseurl = location.protocol + "//" + location.host + location.pathname
        text    = "いい曲できた"
        func    = encodeURIComponent processor.func

        lis = [
            "http://twitter.com/share?lang=ja"
            "text=" + text
            "url=" + encodeURIComponent "#{baseurl}?#{func}&"
        ]
        url = lis.join "&"
        window.open url, "intent", "width=#{w},height=#{h},left=#{x},top=#{y}"

    if (q = location.search.substr 1, -1)
        $func.val decodeURIComponent q
    else if history[0]
        $func.val history[0]

    commit()


    if not /(iphone|ipad|android)/i.test navigator.userAgent
        $('#play').click()
