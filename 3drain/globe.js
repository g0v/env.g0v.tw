(function(){
  $(function(){
    var yearPerSec, gregorianDate, cartesian3Scratch, HealthAndWealthDataSource, viewer, layers, x$, healthAndWealth, highlightBarHandler, c, restoreCamera;
    yearPerSec = 86400 * 365;
    gregorianDate = new Cesium.GregorianDate;
    cartesian3Scratch = new Cesium.Cartesian3;
    HealthAndWealthDataSource = function(){
      this._name = 'Health and Wealth';
      this._entityCollection = new Cesium.EntityCollection;
      this._clock = import$(new Cesium.DataSourceClock, {
        startTime: Cesium.JulianDate.fromIso8601('2014-08-12'),
        currentTime: Cesium.JulianDate.fromIso8601('2014-08-12'),
        stopTime: Cesium.JulianDate.fromIso8601('2014-08-16'),
        clockRange: Cesium.ClockRange.LOOP_STOP,
        clockStep: Cesium.ClockStep.SYSTEM_CLOCK_MULTIPLIER,
        multiplier: 2700
      });
      this._changed = new Cesium.Event;
      this._error = new Cesium.Event;
      this._isLoading = false;
      this._loading = new Cesium.Event;
      this._wealthScale = d3.scale.log().domain([300, 100000]).range([0, 10000000]);
      this._healthScale = d3.scale.linear().domain([0, 100]).range([0, 100000]);
      this._populationScale = d3.scale.sqrt().domain([0, 500000000]).range([5, 5]);
      this._colorScale = d3.scale.category20c();
      return this._selectedEntity = undefined;
    };
    Object.defineProperties(HealthAndWealthDataSource.prototype, {
      name: {
        get: function(){
          return this._name;
        }
      },
      clock: {
        get: function(){
          return this._clock;
        }
      },
      entities: {
        get: function(){
          return this._entityCollection;
        }
      },
      selectedEntity: {
        get: function(){
          return this._selectedEntity;
        },
        set: function(e){
          var entity;
          if (Cesium.defined(this._selectedEntity)) {
            entity = this._selectedEntity;
            entity.polyline.material.color = new Cesium.ConstantProperty(Cesium.Color.fromCssColorString(this._colorScale(entity.region)));
          }
          if (Cesium.defined(e)) {
            e.polyline.material.color = new Cesium.ConstantProperty(Cesium.Color.fromCssColorString('#00ff00'));
          }
          return this._selectedEntity = e;
        }
      },
      isLoading: {
        get: function(){
          return this._isLoading;
        }
      },
      changedEvent: {
        get: function(){
          return this._changed;
        }
      },
      errorEvent: {
        get: function(){
          return this._error;
        }
      },
      loadingEvent: {
        get: function(){
          return this._loading;
        }
      }
    });
    HealthAndWealthDataSource.prototype.loadUrl = function(url){
      var this$ = this;
      if (!Cesium.defined(url)) {
        throw new Cesium.DeveloperError('url must be defined.');
      }
      return Cesium.when(Cesium.loadJson(url), function(json){
        var e;
        try {
          return this$.load(json);
        } catch (e$) {
          e = e$;
          return console.error(e);
        }
      }).otherwise(function(error){
        this$._error.raiseEvent(this$, error);
        return Cesium.when.reject(error);
      });
    };
    HealthAndWealthDataSource.prototype.load = function(data){
      var ellipsoid, entities, influxUrl, this$ = this;
      if (!Cesium.defined(data)) {
        throw new Cesium.DeveloperError('data must be defined.');
      }
      ellipsoid = viewer.scene.globe.ellipsoid;
      this._setLoading(true);
      entities = this._entityCollection;
      entities.suspendEvents();
      entities.removeAll();
      influxUrl = 'http://clocktower-futureboy-1.c.influxdb.com:8086/db/cwbrain/series?u=guest&p=guest&q=select%20*%20from%20%2Frain1hr%5C..%2B%2F%20where%20time%20%3E%20%272014-08-11%27%20and%20time%20%3C%20%272014-08-16%27';
      return Cesium.when(Cesium.loadJson(influxUrl), function(json){
        var rain_1hr, res$, i$, len$, ref$, name, points, station, rain_points, surfacePosition, rain, sampledRain, j$, len1$, ref1$, time, _, r, heightPosition, dt, polyline, outlineMaterial, entity;
        res$ = {};
        for (i$ = 0, len$ = json.length; i$ < len$; ++i$) {
          ref$ = json[i$], name = ref$.name, points = ref$.points;
          res$[name] = points;
        }
        rain_1hr = res$;
        for (i$ = 0, len$ = (ref$ = data).length; i$ < len$; ++i$) {
          station = ref$[i$];
          rain_points = rain_1hr["rain1hr." + station.stationId];
          if (!rain_points) {
            continue;
          }
          surfacePosition = Cesium.Cartesian3.fromDegrees(station.lng, station.lat, 0);
          rain = new Cesium.SampledPositionProperty;
          sampledRain = new Cesium.SampledProperty(Number);
          for (j$ = 0, len1$ = rain_points.length; j$ < len1$; ++j$) {
            ref1$ = rain_points[j$], time = ref1$[0], _ = ref1$[1], r = ref1$[2];
            heightPosition = Cesium.Cartesian3.fromDegrees(station.lng, station.lat, this$._healthScale(r), ellipsoid, cartesian3Scratch);
            dt = Cesium.JulianDate.fromDate(new Date(time));
            rain.addSample(dt, heightPosition);
            sampledRain.addSample(dt, r);
          }
          polyline = new Cesium.PolylineGraphics;
          polyline.show = new Cesium.ConstantProperty(true);
          outlineMaterial = new Cesium.PolylineOutlineMaterialProperty;
          outlineMaterial.color = new Cesium.ConstantProperty(Cesium.Color.fromCssColorString(this$._colorScale("XXX")));
          outlineMaterial.outlineColor = new Cesium.ConstantProperty(new Cesium.Color(0, 0, 0, 1));
          outlineMaterial.outlineWidth = new Cesium.ConstantProperty(3);
          polyline.material = outlineMaterial;
          polyline.width = new Cesium.ConstantProperty(15);
          polyline.followSurface = new Cesium.ConstantProperty(false);
          entity = new Cesium.Entity(station.stationId);
          entity.polyline = polyline;
          polyline.positions = new Cesium.PositionPropertyArray([new Cesium.ConstantPositionProperty(surfacePosition), rain]);
          entity.addProperty('surfacePosition');
          entity.surfacePosition = surfacePosition;
          entity.addProperty('stationData');
          entity.stationData = station;
          entity.addProperty('rain');
          entity.rain = sampledRain;
          entities.add(entity);
        }
        entities.resumeEvents();
        this$._changed.raiseEvent(this$);
        return this$._setLoading(false);
      });
    };
    HealthAndWealthDataSource.prototype._setLoading = function(isLoading){
      if (this._isLoading !== isLoading) {
        this._isLoading = isLoading;
        return this._loading.raiseEvent(this, isLoading);
      }
    };
    HealthAndWealthDataSource.prototype._setInfoDialog = function(time){
      var lifeExpectancy, income, population;
      if (Cesium.defined(this._selectedEntity)) {
        lifeExpectancy = this._selectedEntity.lifeExpectancy.getValue(time);
        income = this._selectedEntity.income.getValue(time);
        population = this._selectedEntity.population.getValue(time);
        $('#info table').remove();
        $('#info').append('<table>             <tr><td>Life Expectancy:</td><td>' + parseFloat(lifeExpectancy).toFixed(1 + '</td></tr>            <tr><td>Income:</td><td>' + parseFloat(income).toFixed(1 + '</td></tr>            <tr><td>Population:</td><td>' + parseFloat(population).toFixed(1 + '</td></tr>            </table>            '))));
        $('#info table').css('font-size', '12px');
        $('#info').dialog({
          title: this._selectedEntity.id,
          width: 300,
          height: 150,
          modal: false,
          position: {
            my: 'right center',
            at: 'right center',
            of: 'canvas'
          },
          show: 'slow',
          beforeClose: function(event, ui){
            return $('#info').data('dataSource').selectedEntity = undefined;
          }
        });
        return $('#info').data('dataSource', this);
      }
    };
    HealthAndWealthDataSource.prototype.update = function(time){
      var currentYear;
      Cesium.JulianDate.toGregorianDate(time, gregorianDate);
      currentYear = gregorianDate.year + gregorianDate.month / 12;
      if (currentYear !== this._year && typeof window.displayYear !== 'undefined') {
        window.displayYear(currentYear);
        this._year = currentYear;
        this._setInfoDialog(time);
      }
      return true;
    };
    $('input[name=\'healthwealth\']').change(function(d){
      var entities, i$, len$, entity;
      entities = healthAndWealth.entities.entities;
      healthAndWealth.entities.suspendEvents();
      for (i$ = 0, len$ = entities.length; i$ < len$; ++i$) {
        entity = entities[i$];
        entity.polyline.positions = new Cesium.PositionPropertyArray([
          new Cesium.ConstantPositionProperty(entity.surfacePosition), d.target.id === 'health'
            ? entity.health
            : entity.wealth
        ]);
      }
      return healthAndWealth.entities.resumeEvents();
    });
    viewer = window.viewer = new Cesium.Viewer('cesiumContainer', {
      fullscreenElement: document.body,
      sceneMode: Cesium.SceneMode[3],
      infoBox: false,
      baseLayerPicker: false
    });
    console.log('foo');
    layers = viewer.scene.imageryLayers;
    layers.addImageryProvider(new Cesium.SingleTileImageryProvider({
      url: '/img/g0v-2line-transparent-darkbackground-m.png',
      rectangle: Cesium.Rectangle.fromDegrees(121.8, 24.0, 122.68, 24.6)
    }));
    import$(viewer.clock, {
      clockRange: Cesium.ClockRange.LOOP_STOP,
      startTime: Cesium.JulianDate.fromIso8601('2014-08-01'),
      currentTime: Cesium.JulianDate.fromIso8601('2014-08-01'),
      stopTime: Cesium.JulianDate.fromIso8601('2014-08-20'),
      clockStep: Cesium.ClockStep.SYSTEM_CLOCK_MULTIPLIER,
      multiplier: 60
    });
    x$ = viewer.animation.viewModel;
    x$.setShuttleRingTicks([1, 5, 10, 50].map((function(it){
      return it * 60;
    })));
    healthAndWealth = new HealthAndWealthDataSource;
    healthAndWealth.loadUrl('stations.json');
    viewer.dataSources.add(healthAndWealth);
    highlightBarHandler = new Cesium.ScreenSpaceEventHandler(viewer.scene.canvas);
    highlightBarHandler.setInputAction(function(movement){
      var pickedObject;
      pickedObject = viewer.scene.pick(movement.endPosition);
      if (Cesium.defined(pickedObject) && Cesium.defined(pickedObject.id)) {
        if (Cesium.defined(pickedObject.id.stationData)) {
          sharedObject.dispatch.nationMouseover(pickedObject.id.stationData, pickedObject);
          return healthAndWealth.selectedEntity = pickedObject.id;
        }
      }
    }, Cesium.ScreenSpaceEventType.MOUSE_MOVE);
    /*
    flyToHandler = new Cesium.ScreenSpaceEventHandler viewer.scene.canvas
    flyToHandler.setInputAction ((movement) ->
      pickedObject = viewer.scene.pick movement.position
      sharedObject.flyTo pickedObject.id.stationData if (Cesium.defined pickedObject) && Cesium.defined pickedObject.id), Cesium.ScreenSpaceEventType.LEFT_CLICK
    */
    sharedObject.dispatch.on('nationMouseover.cesium', function(nationObject){
      $('#info table').remove();
      $('#info').append('<table>         <tr><td>Rain:</td><td>' + parseFloat(nationObject.rain).toFixed(1 + '</td></tr> </table>        '));
      $('#info table').css('font-size', '12px');
      return $('#info').dialog({
        title: nationObject.name,
        width: 300,
        height: 150,
        modal: false,
        position: {
          my: 'right center',
          at: 'right bottom',
          of: 'canvas'
        },
        show: 'slow'
      });
    });
    c = JSON.parse("{\"position\":{\"x\":-3402445.5906561594,\"y\":5220031.43991978,\"z\":2505532.7809903235},\"direction\":{\"x\":0.8887502899941634,\"y\":-0.450840135102767,\"z\":0.0828619008666804},\"up\":{\"x\":0.2770358152708621,\"y\":0.6722989169384074,\"z\":0.686487671490057},\"right\":{\"x\":-0.3652041607692962,\"y\":-0.5871604028530465,\"z\":0.7224047217772037},\"transform\":[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],\"frustum\":{\"fov\":1.0471975511965976,\"near\":1,\"far\":5000000,\"aspectRatio\":1.827922077922078}}");
    restoreCamera = function(camera, c){
      var i$, ref$, len$, k, ref1$;
      for (i$ = 0, len$ = (ref$ = ['position', 'direction', 'up', 'right']).length; i$ < len$; ++i$) {
        k = ref$[i$];
        camera[k] = (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args), t;
          return (t = typeof result)  == "object" || t == "function" ? result || child : child;
  })(Cesium.Cartesian3, [(ref1$ = c[k])['x'], ref1$['y'], ref1$['z']], function(){});
      }
      camera.transform = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args), t;
        return (t = typeof result)  == "object" || t == "function" ? result || child : child;
  })(Cesium.Matrix4, c.transform, function(){});
      camera.frustum = new Cesium.PerspectiveFrustum;
      return import$(camera.frustum, c.frustum);
    };
    restoreCamera(viewer.scene.camera, c);
    return sharedObject.flyTo = function(nationData){
      var ellipsoid, destination, destCartesian;
      ellipsoid = viewer.scene.globe.ellipsoid;
      destination = Cesium.Cartographic.fromDegrees(nationData.lng, nationData.lat - 5, 10000000);
      destCartesian = ellipsoid.cartographicToCartesian(destination);
      destination = ellipsoid.cartesianToCartographic(destCartesian);
      if (!ellipsoid.cartographicToCartesian(destination).equalsEpsilon(viewer.scene.camera.positionWC, Cesium.Math.EPSILON6)) {
        return viewer.scene.camera.flyTo({
          destination: destCartesian
        });
      }
    };
  });
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
