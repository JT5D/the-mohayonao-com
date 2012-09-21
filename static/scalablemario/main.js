(function(){jQuery(function(){"use strict";var e,t,n,r,i,s,o,u,a,f,l,c,h,p,d,v,m,g,y,b;return d=T("efx.delay",100,.4,.25),o=104,i=SC.Scale.major(),r=60,c=SC.Tuning.et12(),l=SC.Scale.minor(),f=r.midicps()*.5,a=function(e){var t,n;return n=e-r,t=i.performKeyToDegree(n),l.degreeToFreq2(t,f,0)},v=T("mml",["o6l16q4eere rcer gr8. > gr8.","o6l16q4cr8>gr8er rarb rb-arl12g<eg l16arfg rerc d>br8","o6l16q4r8gg-fd#re r>g#a<c r>a<cdr8gg-fd#re < rcrc cr8.>r8gg-fd#re r>g#a<c r>a<cdr8e-r8dr8cr8.r4","o6l16q4ccrc rcdr ecr>a gr8.<ccrc rcde r2ccrc rcdr ecr>a gr8.","o6l16q4ecr>g r8g#r a<frf> ar8.l12b<aa agf l16ecr>a gr8.<ecr>g r8g#r a<frf> ar8.l12b<ff fed l16c>grg cr8."]),v.synth=T("+").appendTo(d),v.synthdef=function(e,t){var n;return n=T("*",T("osc","pulse",0,.25),T("adsr",0,500,.8,150)),n.keyon=function(e){return n.args[0].freq.value=a(e.tnum),n.args[1].bang()},n.keyoff=function(e){return n.args[1].keyoff()},n},v.bpm=o,m=T("mml",["o5l16q4f#f#rf# rf#f#r gr8. >gr8.","o5l16q4er8cr8>gr <rcrd rd-crl12cg<c l16cr>ab rgre fdr8","o6l16q4r8ee-d>b<rc r>efa rfab<r8ee-d>b<rc rgrg gr8.r8ee-d>b<rc r>efa rfab<r8cr8>fr8er8.r4","o5l16q4a-a-ra- ra-b-r <c>grf er8.a-a-ra- ra-b-g r2a-a-ra- ra-b-r <c>grf er8.","o6l16q4c>gre r8er  f<drd> fr8.l12g<ff fed l16c>grf er8.<c>gre r8er  f<drd> fr8.l12g<dd dc>b l16er8.r4"]),m.synth=T("+").appendTo(d),m.synthdef=function(e,t){var n;return n=T("*",T("osc","pulse",0,.25),T("adsr",0,500,.8,150)),n.keyon=function(e){return n.args[0].freq.value=a(e.tnum),n.args[1].bang()},n.keyoff=function(e){return n.args[1].keyoff()},n},m.bpm=o,s=T("mml",["o4l16q4ddrd rddr <br8.>gr8.","o4l16q4gr8er8cr rfrg rg-frl12e<ce l16frde rcr>a bgr8","o4l16q4cr8gr8<cr >fr8<ccr>frcr8er8g<c < rfrf fr >>grcr8gr8<cr >fr8<ccr>fr>a-r<a-r> b-<b-r8> l16cr8>g grcr","o3l16q4[a-r8<e-r8a-r gr8cr8>gr]3","o4l16q4 crre gr<cr> fr<cr cc>frdrrf grbr gr<cr cc>grcrre gr<cr> fr<cr cc>frgrrg l12gab l16 <cr>gr cr8."]),s.synth=T("+").appendTo(d),s.synthdef=function(e,t){var n;return n=T("*",T("osc","fami",0,.8),T("adsr",0,500,.8,150)),n.keyon=function(e){return n.args[0].freq.value=a(e.tnum),n.args[1].bang()},n.keyoff=function(e){return n.args[1].keyoff()},n},s.bpm=o,y=[0,1,1,2,2,3,0,1,1,4,4,3],p=0,v.onended=function(){return p=(p+1)%y.length,v.selected=m.selected=s.selected=y[p],v.bang(),m.bang(),s.bang()},u=[v,m,s],d.buddy("play",u,"on"),d.buddy("pause",u,"off"),h=function(){switch(timbre.env){case"webkit":return"timbre.js on Web Audio API / subcollider.js";case"moz":return"timbre.js on Audio Data API / subcollider.js";default:return"Please open with Chrome or Firefox"}}(),$("#desc").text(h),$("#play").on("click",function(){if(!d.isPlaying)return d.play(),d.isPlaying=!0}),$("#pause").on("click",function(){if(d.isPlaying)return d.pause(),d.isPlaying=!1}),e=$("#scale"),g=function(){return g={},Object.keys(SC.ScaleInfo.scales).forEach(function(t){var n;n=SC.ScaleInfo.at(t);if(n.pitchesPerOctave()!==12)return;return g[t]=n,e.append($("<option>").attr({value:t}).text(n.name))}),g}(),e.on("change",function(){return l=g[$(this).val()],l.tuning(c)}),e.val("major").change(),$("#random-scale").on("click",function(){return e.val(Object.keys(g).choose()).change()}),t=$("#tuning"),b=function(){return b={},Object.keys(SC.TuningInfo.tunings).forEach(function(e){var n;n=SC.TuningInfo.at(e);if(n.size()!==12)return;return b[e]=n,t.append($("<option>").attr({value:e}).text(n.name))}),b}(),t.on("change",function(){return c=b[$(this).val()],l.tuning(c)}),t.val("et12"),$("#random-tuning").on("click",function(){return t.val(Object.keys(b).choose()).change()}),SC.Scale.prototype.degreeToFreq2=function(e,t,n){return this.degreeToRatio2(e,n)*t},SC.Scale.prototype.degreeToRatio2=function(e,t){var n;return t+=e/this._degrees.length|0,n=e%this._degrees.length,this.ratios().blendAt(n)*Math.pow(this.octaveRatio(),t)},location.search!==""&&(n=function(){return n={},location.search.substr(1).split("&").forEach(function(e){var t;return t=e.split("=",2),t.length===1?n[t[0]]=!0:n[t[0]]=t[1]}),n}(),n.scale!==""&&e.val(n.scale).change(),n.tuning!==""&&t.val(n.tuning).change(),n.autostart&&$("#play").click()),$("#tweet").on("click",function(){var e,t,n,r,i,s,o,u,a,f,l;return r=$("#scale").val(),o=$("#tuning").val(),a=550,t=250,f=Math.round(screen.width*.5-a*.5),l=Math.round(screen.height*.5-t*.5),e=location.protocol+"//"+location.host+location.pathname,s="マリオの曲できた",i="scale="+r+"&tuning="+o,console.log(e),n=["http://twitter.com/share?lang=ja","text="+s,"url="+encodeURIComponent(""+e+"?"+i)],u=n.join("&"),window.open(u,"intent","width="+a+",height="+t+",left="+f+",top="+l)})})}).call(this)