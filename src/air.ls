
metrics = do
  NO2: {}
  'PM2.5':
    domain: [0, 20, 35, 70, 100]
    name: \細懸浮
    unit: \μg/m³
  PM10:
    domain: [0, 50, 150, 350, 420]
    unit: \μg/m³
    name: \懸浮微粒
  PSI:
    domain: [0, 50, 100, 200, 300]
    name: \污染指數
  SO2:
    name: \二氧化硫
  CO: {}
  O3:
    domain: [0, 40, 80, 120, 300]
    name: \臭氧
    unit: \ppb
  RAIN:
    domain: [1 2 6 10 15 20 30 40 50 70 90 110 130 150 200 300]
    name: \雨量
<- $

window-width = $(window) .width!

if window-width > 998
  width = $(window) .height! / 4 * 3
  width <?= 687
else
  width = $(window) .width!

margin-top = \65px

height = width * 4 / 3

wrapper = d3.select \body
          .append \div
          .style \width, width + \px
          .style \height, height + \px
          .style \position, \absolute
          .style \margin-top, margin-top
          .style \top, \0px
          .style \left, \0px
          .style \overflow, \hidden

canvas = wrapper.append \canvas
          .attr \width, width
          .attr \height, height
          .style \position, \absolute

canvas.origin = [0 0]
canvas.scale = 1

svg = d3.select \body
      .append \svg
      .attr \width, width
      .attr \height, height
      .style \position, \absolute
      .style \top, \0px
      .style \left, \0px
      .style \margin-top, margin-top

g = svg.append \g
      .attr \id, \taiwan
      .attr \class, \counties

history = d3.select \#history
  .style \top \-400px
  .style \left \-200px
  .style \width \400px
  .style \height \200px
  .style \z-index 100

x-off = width - 100 - 40
y-off = height - (32*7) - 40

legend = svg.append \g
  .attr \class, \legend
  .attr "transform" ->
    "translate(#{x-off},#{y-off})"

legend
  ..append \rect
    .attr \width 100
    .attr \height 32*7
    .attr \x 20
    .attr \y 0
    .style \fill \#000000
    .style \stroke \#555555
    .style \stroke-width 2
  ..append \svg:image
    .attr \xlink:href '/img/g0v-2line-black-s.png'
    .attr \x 20
    .attr \y 1
    .attr \width 100
    .attr \height 60
  ..append \text
    .attr \x 33
    .attr \y 30*7 + 10
    .text 'env.g0v.tw'
    .style \fill \#EEEEEE
    .style \font-size \13px
    .style \font-family \Orbitron

$ document .ready ->
  panel-width = $ \#main-panel .width!
  if window-width - panel-width > 1200
    $ \#main-panel .css \margin-right, panel-width

  $ \.data.button .on \click ->
    it.preventDefault!
    $ \#main-panel .toggle!
    $ \#info-panel .hide!

  $ \.forcest.button .on \click ->
    it.preventDefault!
    $ \#info-panel .toggle!
    $ \#main-panel .hide!

  $ \.launch.button .on \click ->
    it.preventDefault!
    $ \#info-panel .hide!
    sidebar = $ '.sidebar'
    sidebar.sidebar \toggle

# inspector = d3.select \body
#               .append \div
#               .attr \class \inspector
#               .style \opacity 0

# station-label = inspector.append "p"
# rainfall-label = inspector.append "p"


min-latitude = 21.5 # min-y
max-latitude = 25.5 # max-y
min-longitude = 119.5 # min-x
max-longitude = 122.5 # max-x
dy = (max-latitude - min-latitude) / height
dx = (max-longitude - min-longitude) / width

proj = ([x, y]) ->
  [(x - min-longitude) / dx, height - (y - min-latitude) / dy]

path = d3.geo.path!projection proj

### Draw Taiwan
draw-taiwan = (countiestopo) ->
  for layer-name, topo-objects of countiestopo.objects
    counties = topojson.feature countiestopo, topo-objects

    g.selectAll 'path'
      .data counties.features
      .enter!append 'path'
      .attr 'class', -> \q-9-9
      .attr 'd', path

ConvertDMSToDD = (days, minutes, seconds) ->
  days = +days
  minutes = +minutes
  seconds = +seconds
  dd = minutes/60 + seconds/(60*60)
  return if days > 0
    days + dd
  else
    days - dd

draw-stations = (stations) ->
  g.selectAll \circle
    .data stations
    .enter!append 'circle'
    .style \stroke \white
    .style \fill \none
    .attr \r 2
    .attr "transform" ->
        "translate(#{ proj [+it.lng, +it.lat] })"

var current-metric, current-unit
var color-of
var stations

set-metric = (name) ->

  current-metric := name
  if location.pathname.match /^\/air/
    color-of := d3.scale.linear!
    .domain metrics[name].domain ? [0, 50, 100, 200, 300]
    .range [ d3.hsl(100, 1.0, 0.6)
             d3.hsl(60, 1.0, 0.6)
             d3.hsl(30, 1.0, 0.6)
             d3.hsl(0, 1.0, 0.6)
             d3.hsl(0, 1.0, 0.1) ]
  else
    color-of := d3.scale.quantile!
    .domain metrics[name].domain ? [ 1 2 6 10 15 20 30 40 50 70 90 110 130 150 200 300 ]
    .range <[ #c5bec2 #99feff #00ccfc #0795fd #025ffe #3c9700 #2bfe00 #fdfe00 #ffcb00 #eaa200 #f30500 #d60002 #9e0003 #9e009d #d400d1 #fa00ff #facefb]>
  current-unit := metrics[name].unit ? ''

  add-list stations

  legend.selectAll("g.entry").data color-of.domain!
    ..enter!append \g .attr \class \entry
      ..append \rect
      ..append \text
    ..each (d, i) ->
      if location.pathname.match /^\/air/
        d3.select @
          ..select 'rect'
            .attr \width 20
            .attr \height 20
            .attr \x 30
            .attr \y -> (i+2)*30
            .style \fill (d) -> color-of d
          ..select \text
            .attr \x 55
            .attr \y -> (i+2)*30+15
            .attr \d \.35em
            .text -> &0 + current-unit
            .style \fill \#AAAAAA
            .style \font-size \10px
      else
        d3.select @
          ..select 'rect'
            .attr \width 10
            .attr \height 10
            .attr \x 30
            .attr \y -> (i+2)*10+25
            .style \fill (d) -> color-of d
          ..select \text
            .attr \x 55
            .attr \y -> (i+2)*10+35
            .attr \d \.35em
            .text -> &0 + current-unit
            .style \fill \#AAAAAA
            .style \font-size \10px
    ..exit!remove!

  draw-heatmap stations

draw-segment = (d, i) ->
  d3.select \#station-name
  .text d.name

  if epa-data[d.name]? and not isNaN epa-data[d.name][current-metric]
    raw-value = (parseInt epa-data[d.name][current-metric]) + ""
    update-seven-segment (" " * (0 >? 4 - raw-value.length)) + raw-value
  else
    update-seven-segment "----"

add-list = (stations) ->
  list = d3.select \div.sidebar
  list.selectAll \a
    .data stations
    .enter!append 'a'
    .attr \class, \item
    .text ->
      it.SiteName
    .on \click (d, i) ->
      draw-segment d, i
      $ \.launch.button .click!
      $ \#main-panel .css \display, \block

#console.log [[+it.longitude, +it.latitude, it.name] for it in stations]
#root = new Firebase "https://cwbtw.firebaseio.com"
#current = root.child "rainfall/current"

epa-data = {}

# [[x, y, z], …]
samples = {}


# p1: [x1, y1]
# p2: [x2, y2]
# return (x1-x2)^2 + (y1-y2)
distanceSquare = ([x1, y1], [x2, y2]) ->
  (x1 - x2) ** 2 + (y1 - y2) ** 2

# samples: [[x, y, z], …]
# power: positive integer
# point: [x, y]
# return z
idw-train = (samples) ->
  sx=[]
  sy=[]
  sz=[]
  for s in samples
    sx.push s[0]
    sy.push s[1]
    sz.push s[2]
  kriging.train sz, sx, sy, "exponential", 0, 100

idw-pred = (variogram, point) ->
  kriging.predict point[0], point[1], variogram

y-pixel = 0

plot-interpolated-data = (ending) ->
  y-pixel := height

  steps = 2
  starts = [ 2 to 2 * (steps - 1) by 2 ]

  render-line = ->
    c = canvas.node!.getContext \2d
    variogram = idw-train samples
    for x-pixel from 0 to width by 2
      y = min-latitude + dy * ((y-pixel + zoom.translate![1] - height) / zoom.scale! + height)
      x = min-longitude + dx * ((x-pixel - zoom.translate![0]) / zoom.scale!)
      z = 0 >? idw-pred variogram, [x, y]

      c.fillStyle = color-of z
      c.fillRect x-pixel, height - y-pixel, 2, 2

    if y-pixel >= 0
      y-pixel := y-pixel - 2 * steps
      set-timeout render-line, 0
    else if starts.length > 0
      y-pixel := height - starts.shift!
      set-timeout render-line, 0
    else if ending
      set-timeout ending, 0

  render-line!

# value should be a four-character-length string.
update-seven-segment = (value-string) ->
  pins = "abcdefg"
  seven-segment-char-map =
    ' ': 0x00
    '-': 0x40
    '0': 0x3F
    '1': 0x06
    '2': 0x5B
    '3': 0x4F
    '4': 0x66
    '5': 0x6D
    '6': 0x7D
    '7': 0x07
    '8': 0x7F
    '9': 0x6F

  d3.selectAll \.seven-segment
    .data value-string
    .each (d, i) ->
      bite = seven-segment-char-map[d]

      for i from 0 to pins.length - 1
        bit = Math.pow 2 i
        d3.select this .select ".#{pins[i]}" .classed \on, (bit .&. bite) == bit

function piped(url)
  url -= /^https?:\/\//
  return "https://cors-anywhere.herokuapp.com/#url"

#current.on \value ->
draw-heatmap = (stations) ->
  d3.select \#rainfall-timestamp
    .text "#{epa-data.士林.PublishTime}"

  d3.select \#station-name
    .text "已更新"

  update-seven-segment "    "
  samples := for st in stations when epa-data[st.name]?
    val = parseFloat epa-data[st.name][current-metric]
    # XXX mark NaN stations
    continue if isNaN val
    [+st.lng, +st.lat, val]

  while samples.length > 100
    samples := for st in samples when (Math.random! > 0.5)
      st

  # update station's value
  svg.selectAll \circle
    .data stations
    .style \fill (st) ->
      \#FFFFFF
      # if epa-data[st.name]? and not isNaN epa-data[st.name][current-metric]
      #   value = parseFloat epa-data[st.name][current-metric]
      #   color = color-of parseFloat epa-data[st.name][current-metric]
      #   color if value >= 0
      # else
      #   \#FFFFFF
    .on \mouseover (d, i) ->
      draw-segment d, i
      {clientX: x, clientY: y} = d3.event
      history
        .style \left x + \px
        .style \top y + \px

      sitecode = d.SiteCode
      err, req <- d3.xhr "http://graphite.gugod.org/render/?_salt=1392034055.328&lineMode=connected&from=-24hours&target=epa.aqx.site_code.#{sitecode}.pm25&format=csv"
      datum = d3.csv.parseRows req.responseText, ([_, date, value]) ->
        { date, value: parse-float value}
      return unless datum.length
      history.chart.load columns: [
        ['pm2.5'] ++ [value for {value} in datum]
        ['x'] ++ [date for {date} in datum]
      ]
      history.chart.resize!

  # plot interpolated value
  plot-interpolated-data!

setup-history = ->
  chart = c3.generate do
    bindto: '#history'
    data:
      x: 'x'
      x_format: '%Y-%m-%d %H:%M:%S'
      columns: [
        ['x', '2014-01-01 00:00:00']
        ['pm2.5', 0]
      ]
    legend: {-show}
    axis:
      x: {type : 'timeseries' }
  history.chart = chart

aqx-csv-url-with-time = (t) ->
  year  = t.substr 0,4
  month = t.substr 4,2
  day   = t.substr 6,2
  hour  = t.substr 8,2
  min   = t.substr 10,2
  return "https://raw.githubusercontent.com/g0v-data/mirror-#{year}/master/epa/aqx/#{year}-#{month}-#{day}/#{hour}-#{min}.csv"

# original aqx_url: http://opendata.epa.gov.tw/ws/Data/AQX/?$orderby=SiteName&$skip=0&$top=1000&format=csv
draw-all = (_stations, aqx_url = 'http://g0v-data-mirror.gugod.org/epa/aqx.csv' ) ->
  if location.pathname.match /^\/air/
    stations := for s in _stations
      s.lng = s.TWD97Lon
      s.lat = s.TWD97Lat
      s.name = s.SiteName
      s
    <- d3.csv piped aqx_url
    epa-data := {[e.SiteName, e] for e in it}
    set-metric \PM2.5
    $ \.psi .click ->
      set-metric \PSI
    $ \.pm10 .click ->
      set-metric \PM10
    $ \.pm25 .click ->
      set-metric \PM2.5
    $ \.o3 .click ->
      set-metric \O3
  else
    stations := _stations
    <- d3.json '/rainfall.json'
    epa-data := {[e.name, e] for e in it}
    set-metric \RAIN
  draw-stations stations




zoom = d3.behavior.zoom!
  .on \zoom ->
    g.attr \transform 'translate(' + d3.event.translate.join(\,) + ')scale(' + d3.event.scale + ')'
    g.selectAll \path
      .attr \d path.projection proj
    canvas
      .style \transform-origin, 'top left'
      .style \transform, \translate( + (zoom.translate![0] - canvas.origin[0]) + 'px,' + (zoom.translate![1] - canvas.origin[1]) + 'px)' + \scale( + zoom.scale! / canvas.scale + \)
  .on \zoomend ->
    canvas := wrapper.insert \canvas, \canvas
              .attr \width, width
              .attr \height, height
              .style \position, \absolute
    canvas.origin = zoom.translate!
    canvas.scale = zoom.scale!
    plot-interpolated-data ~> wrapper.selectAll \canvas .data [0] .exit!.remove!

if location.pathname.match /^\/air/
  now = (new Date!).getTime!
  setup-history!
  countiestopo, stations <- (done) ->
    if localStorage.countiestopo and localStorage.stations
      countiestopo = JSON.parse localStorage.countiestopo
      stations = JSON.parse localStorage.stations
      if countiestopo.lastUpdated and now - countiestopo.lastUpdated < (86400 * 1000 * 7)
        return done countiestopo, stations
    countiestopo <- d3.json "/twCounty2010.topo.json"
    try localStorage.countiestopo = JSON.stringify countiestopo <<< lastUpdated: now
    stations <- d3.csv "/epa-site.csv"
    try localStorage.stations = JSON.stringify stations
    done countiestopo, stations

  draw-taiwan countiestopo

  if matched = location.search.match /[\?\&\;]t=([0-9]+)(?:[^0-9]|$)/
    draw-all stations, aqx-csv-url-with-time matched[1]
  else
    draw-all stations
  svg.call zoom
else
  stations <- d3.json "/stations.json"
  draw-all stations
