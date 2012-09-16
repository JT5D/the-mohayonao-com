$ ->
    'use stric'

    prettyPrint()

    mtof = timbre.utils.mtof
    choice = (list)->
        list[(Math.random() * list.length)|0]

    formants =
        a:[700, 1200, 2900]
        i:[300, 2700, 2700]
        u:[390, 1200, 2500]
        e:[450, 1750, 2750]
        o:[460,  880, 2800]

    freq  = 174.61412048339844
    synth = T('saw', T('+', freq, T('sin', 3, 0.8).kr()).kr())
    orig  = synth

    f1 = T('rbpf').set(cutoff:T('glide', 150,  700), Q:0.9, depth:0.45).append synth
    f2 = T('rbpf').set(cutoff:T('glide', 150, 1200), Q:0.9, depth:0.65).append synth
    f3 = T('rbpf').set(cutoff:T('glide', 150, 2900), Q:0.9, depth:0.75).append synth
    synth = T('+', f1, f2, f3)
    synth = T('-', synth, orig).set(mul:0.4)
    synth = T('bpf').set(freq:2700, band:0.25).append synth

    timer = T 'interval', 250, ->
        f = formants[choice 'aiueo']
        f1.cutoff.value = f[0]
        f2.cutoff.value = f[1]
        f3.cutoff.value = f[2]

    synth.buddy 'play' , timer, 'on'
    synth.buddy 'pause', timer, 'off'

    $('#play' ).on 'click', -> synth.play()
    $('#pause').on 'click', -> synth.pause()
