<- $
yearPerSec = 86400 * 365
gregorianDate = new Cesium.GregorianDate
cartesian3Scratch = new Cesium.Cartesian3
HealthAndWealthDataSource = ->
  @_name = 'Health and Wealth'
  @_entityCollection = new Cesium.EntityCollection
  @_clock = new Cesium.DataSourceClock <<< do
    startTime: Cesium.JulianDate.fromIso8601 '2014-08-12'
    currentTime: Cesium.JulianDate.fromIso8601 '2014-08-12'
    stopTime: Cesium.JulianDate.fromIso8601 '2014-08-16'
    clockRange: Cesium.ClockRange.LOOP_STOP
    clockStep : Cesium.ClockStep.SYSTEM_CLOCK_MULTIPLIER
    multiplier: 2700
  @_changed = new Cesium.Event
  @_error = new Cesium.Event
  @_isLoading = false
  @_loading = new Cesium.Event
  @_wealthScale = d3.scale.log!domain [300, 100000] .range [0, 10000000]
  @_healthScale = d3.scale.linear!domain [0, 100] .range [0, 100000]
  @_populationScale = d3.scale.sqrt!domain [0, 500000000] .range [5, 5]
  @_colorScale = d3.scale.category20c!
  @_selectedEntity = ``undefined``
Object.defineProperties HealthAndWealthDataSource.prototype, {
  name: {get: -> @_name}
  clock: {get: -> @_clock}
  entities: {get: -> @_entityCollection}
  selectedEntity: {
    get: -> @_selectedEntity
    set: (e) ->
      if Cesium.defined @_selectedEntity
        entity = @_selectedEntity
        entity.polyline.material.color = new Cesium.ConstantProperty Cesium.Color.fromCssColorString @_colorScale entity.region
      if Cesium.defined e
        e.polyline.material.color = new Cesium.ConstantProperty Cesium.Color.fromCssColorString '#00ff00'
      @_selectedEntity = e
  }
  isLoading: {get: -> @_isLoading}
  changedEvent: {get: -> @_changed}
  errorEvent: {get: -> @_error}
  loadingEvent: {get: -> @_loading}
}
HealthAndWealthDataSource::loadUrl = (url) ->
  throw new Cesium.DeveloperError 'url must be defined.' if not Cesium.defined url
  Cesium.when (Cesium.loadJson url), (json) ~>
    try
      @load json
    catch
      console.error(e)

  .otherwise (error) ~>
    #@_setLoading false
    @_error.raiseEvent @, error
    Cesium.when.reject error
HealthAndWealthDataSource::load = (data) ->
  throw new Cesium.DeveloperError 'data must be defined.' if not Cesium.defined data
  ellipsoid = viewer.scene.globe.ellipsoid
  @_setLoading true
  entities = @_entityCollection
  entities.suspendEvents!
  entities.removeAll!

  influx-url = 'http://clocktower-futureboy-1.c.influxdb.com:8086/db/cwbrain/series?u=guest&p=guest&q=select%20*%20from%20%2Frain1hr%5C..%2B%2F%20where%20time%20%3E%20%272014-08-11%27%20and%20time%20%3C%20%272014-08-16%27'
  json <~ Cesium.when Cesium.loadJson influx-url
  rain_1hr = {[name, points] for {name, points} in json}
  for station in data
    rain_points = rain_1hr["rain1hr.#{station.stationId}"]
    continue unless rain_points
    surfacePosition = Cesium.Cartesian3.fromDegrees station.lng, station.lat, 0

    rain = new Cesium.SampledPositionProperty
    sampledRain = new Cesium.SampledProperty Number
    for [time, _, r] in rain_points
      heightPosition = Cesium.Cartesian3.fromDegrees station.lng, station.lat, (@_healthScale r), ellipsoid, cartesian3Scratch
      dt = Cesium.JulianDate.fromDate new Date time
      rain.addSample dt, heightPosition
      sampledRain.addSample dt, r

    polyline = new Cesium.PolylineGraphics
    polyline.show = new Cesium.ConstantProperty true
    outlineMaterial = new Cesium.PolylineOutlineMaterialProperty
    outlineMaterial.color = new Cesium.ConstantProperty Cesium.Color.fromCssColorString @_colorScale "XXX"
    outlineMaterial.outlineColor = new Cesium.ConstantProperty new Cesium.Color 0, 0, 0, 1
    outlineMaterial.outlineWidth = new Cesium.ConstantProperty 3
    polyline.material = outlineMaterial
    polyline.width = new Cesium.ConstantProperty 15
    polyline.followSurface = new Cesium.ConstantProperty false
    entity = new Cesium.Entity station.stationId
    entity.polyline = polyline
    # XXX construct multi-segment here
    polyline.positions = new Cesium.PositionPropertyArray [(new Cesium.ConstantPositionProperty surfacePosition), rain]
    entity.addProperty 'surfacePosition'
    entity.surfacePosition = surfacePosition
    entity.addProperty 'stationData'
    entity.stationData = station
    entity.addProperty 'rain'
    entity.rain = sampledRain
    entities.add entity
  entities.resumeEvents!
  @_changed.raiseEvent this
  @_setLoading false
HealthAndWealthDataSource::_setLoading = (isLoading) ->
  if @_isLoading isnt isLoading
    @_isLoading = isLoading
    @_loading.raiseEvent this, isLoading
HealthAndWealthDataSource::_setInfoDialog = (time) ->
  if Cesium.defined @_selectedEntity
    lifeExpectancy = @_selectedEntity.lifeExpectancy.getValue time
    income = @_selectedEntity.income.getValue time
    population = @_selectedEntity.population.getValue time
    ($ '#info table').remove!
    ($ '#info').append '<table>             <tr><td>Life Expectancy:</td><td>' + (parseFloat lifeExpectancy).toFixed 1 + '</td></tr>            <tr><td>Income:</td><td>' + (parseFloat income).toFixed 1 + '</td></tr>            <tr><td>Population:</td><td>' + (parseFloat population).toFixed 1 + '</td></tr>            </table>            '
    ($ '#info table').css 'font-size', '12px'
    ($ '#info').dialog {
      title: @_selectedEntity.id
      width: 300
      height: 150
      modal: false
      position: {
        my: 'right center'
        at: 'right center'
        of: 'canvas'
      }
      show: 'slow'
      beforeClose: (event, ui) -> (($ '#info').data 'dataSource').selectedEntity = ``undefined``
    }
    ($ '#info').data 'dataSource', this
HealthAndWealthDataSource::update = (time) ->
  Cesium.JulianDate.toGregorianDate time, gregorianDate
  currentYear = gregorianDate.year + gregorianDate.month / 12
  if currentYear isnt @_year && typeof window.displayYear isnt 'undefined'
    window.displayYear currentYear
    @_year = currentYear
    @_setInfoDialog time
  true
($ 'input[name=\'healthwealth\']').change (d) ->
  {entities} = healthAndWealth.entities
  healthAndWealth.entities.suspendEvents!
  for entity in entities
    entity.polyline.positions = new Cesium.PositionPropertyArray [(new Cesium.ConstantPositionProperty entity.surfacePosition), if d.target.id is 'health' => entity.health else entity.wealth]
  healthAndWealth.entities.resumeEvents!
viewer = window.viewer = new Cesium.Viewer 'cesiumContainer', {
  fullscreenElement: document.body
  sceneMode: Cesium.SceneMode.3D_VIEW
  -infoBox
  -baseLayerPicker
}
console.log \foo

layers = viewer.scene.imageryLayers
layers.addImageryProvider new Cesium.SingleTileImageryProvider do
  url : '/img/g0v-2line-transparent-darkbackground-m.png'
  rectangle : Cesium.Rectangle.fromDegrees(121.8, 24.0, 122.68, 24.6)

viewer.clock <<< do
  clockRange: Cesium.ClockRange.LOOP_STOP
  startTime: Cesium.JulianDate.fromIso8601 '2014-08-01'
  currentTime: Cesium.JulianDate.fromIso8601 '2014-08-01'
  stopTime: Cesium.JulianDate.fromIso8601 '2014-08-20'
  clockStep: Cesium.ClockStep.SYSTEM_CLOCK_MULTIPLIER
  multiplier: 60
viewer.animation.viewModel
  ..setShuttleRingTicks [1 5 10 50].map (* 60)
healthAndWealth = new HealthAndWealthDataSource
healthAndWealth.loadUrl 'stations.json'
viewer.dataSources.add healthAndWealth
highlightBarHandler = new Cesium.ScreenSpaceEventHandler viewer.scene.canvas
highlightBarHandler.setInputAction ((movement) ->
  pickedObject = viewer.scene.pick movement.endPosition
  if (Cesium.defined pickedObject) && Cesium.defined pickedObject.id
    if Cesium.defined pickedObject.id.stationData
      sharedObject.dispatch.nationMouseover pickedObject.id.stationData, pickedObject
      healthAndWealth.selectedEntity = pickedObject.id), Cesium.ScreenSpaceEventType.MOUSE_MOVE
/*
flyToHandler = new Cesium.ScreenSpaceEventHandler viewer.scene.canvas
flyToHandler.setInputAction ((movement) ->
  pickedObject = viewer.scene.pick movement.position
  sharedObject.flyTo pickedObject.id.stationData if (Cesium.defined pickedObject) && Cesium.defined pickedObject.id), Cesium.ScreenSpaceEventType.LEFT_CLICK
*/
sharedObject.dispatch.on 'nationMouseover.cesium', (nationObject) ->
  ($ '#info table').remove!
  ($ '#info').append '<table>         <tr><td>Rain:</td><td>' + (parseFloat nationObject.rain).toFixed 1 + '</td></tr> </table>        '
  ($ '#info table').css 'font-size', '12px'
  ($ '#info').dialog {
    title: nationObject.name
    width: 300
    height: 150
    modal: false
    position: {
      my: 'right center'
      at: 'right bottom'
      of: 'canvas'
    }
    show: 'slow'
  }
c = JSON.parse """
{"position":{"x":-3402445.5906561594,"y":5220031.43991978,"z":2505532.7809903235},"direction":{"x":0.8887502899941634,"y":-0.450840135102767,"z":0.0828619008666804},"up":{"x":0.2770358152708621,"y":0.6722989169384074,"z":0.686487671490057},"right":{"x":-0.3652041607692962,"y":-0.5871604028530465,"z":0.7224047217772037},"transform":[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],"frustum":{"fov":1.0471975511965976,"near":1,"far":5000000,"aspectRatio":1.827922077922078}}
"""
restoreCamera = (camera, c) ->
  for k in <[position direction up right]>
    camera[k] = new Cesium.Cartesian3 ...c[k]<[x y z]>
  camera.transform = new Cesium.Matrix4 ...c.transform
  camera.frustum = new Cesium.PerspectiveFrustum
  camera.frustum <<< c.frustum

restoreCamera viewer.scene.camera, c

sharedObject.flyTo = (nationData) ->
  ellipsoid = viewer.scene.globe.ellipsoid
  destination = Cesium.Cartographic.fromDegrees nationData.lng, nationData.lat - 5, 10000000
  destCartesian = ellipsoid.cartographicToCartesian destination
  destination = ellipsoid.cartesianToCartographic destCartesian
  unless (ellipsoid.cartographicToCartesian destination).equalsEpsilon viewer.scene.camera.positionWC, Cesium.Math.EPSILON6
    viewer.scene.camera.flyTo {destination: destCartesian}
