(function(){
  var metrics, replace$ = ''.replace;
  metrics = {
    NO2: {},
    'PM2.5': {
      domain: [0, 20, 35, 70, 100],
      name: '細懸浮',
      unit: 'μg/m³'
    },
    PM10: {
      domain: [0, 50, 150, 350, 420],
      unit: 'μg/m³',
      name: '懸浮微粒'
    },
    PSI: {
      domain: [0, 50, 100, 200, 300],
      name: '污染指數'
    },
    SO2: {
      name: '二氧化硫'
    },
    CO: {},
    O3: {
      domain: [0, 40, 80, 120, 300],
      name: '臭氧',
      unit: 'ppb'
    },
    RAIN: {
      domain: [1, 2, 6, 10, 15, 20, 30, 40, 50, 70, 90, 110, 130, 150, 200, 300],
      name: '雨量'
    }
  };
  $(function(){
    var windowWidth, width, marginTop, height, wrapper, canvas, svg, g, history, xOff, yOff, legend, x$, minLatitude, maxLatitude, minLongitude, maxLongitude, dy, dx, proj, path, drawTaiwan, ConvertDMSToDD, drawStations, currentMetric, currentUnit, colorOf, stations, setMetric, drawSegment, addList, epaData, samples, distanceSquare, idwTrain, idwPred, yPixel, plotInterpolatedData, updateSevenSegment, drawHeatmap, setupHistory, aqxCsvUrlWithTime, drawAll, zoom, now;
    windowWidth = $(window).width();
    if (windowWidth > 998) {
      width = $(window).height() / 4 * 3;
      width <= 687 || (width = 687);
    } else {
      width = $(window).width();
    }
    marginTop = '65px';
    height = width * 4 / 3;
    wrapper = d3.select('body').append('div').style('width', width + 'px').style('height', height + 'px').style('position', 'absolute').style('margin-top', marginTop).style('top', '0px').style('left', '0px').style('overflow', 'hidden');
    canvas = wrapper.append('canvas').attr('width', width).attr('height', height).style('position', 'absolute');
    canvas.origin = [0, 0];
    canvas.scale = 1;
    svg = d3.select('body').append('svg').attr('width', width).attr('height', height).style('position', 'absolute').style('top', '0px').style('left', '0px').style('margin-top', marginTop);
    g = svg.append('g').attr('id', 'taiwan').attr('class', 'counties');
    history = d3.select('#history').style('top', '-400px').style('left', '-200px').style('width', '400px').style('height', '200px').style('z-index', 100);
    xOff = width - 100 - 40;
    yOff = height - 32 * 7 - 40;
    legend = svg.append('g').attr('class', 'legend').attr("transform", function(){
      return "translate(" + xOff + "," + yOff + ")";
    });
    x$ = legend;
    x$.append('rect').attr('width', 100).attr('height', 32 * 7).attr('x', 20).attr('y', 0).style('fill', '#000000').style('stroke', '#555555').style('stroke-width', 2);
    x$.append('svg:image').attr('xlink:href', '/img/g0v-2line-black-s.png').attr('x', 20).attr('y', 1).attr('width', 100).attr('height', 60);
    x$.append('text').attr('x', 33).attr('y', 30 * 7 + 10).text('env.g0v.tw').style('fill', '#EEEEEE').style('font-size', '13px').style('font-family', 'Orbitron');
    $(document).ready(function(){
      var panelWidth;
      panelWidth = $('#main-panel').width();
      if (windowWidth - panelWidth > 1200) {
        $('#main-panel').css('margin-right', panelWidth);
      }
      $('.data.button').on('click', function(it){
        it.preventDefault();
        $('#main-panel').toggle();
        return $('#info-panel').hide();
      });
      $('.forcest.button').on('click', function(it){
        it.preventDefault();
        $('#info-panel').toggle();
        return $('#main-panel').hide();
      });
      return $('.launch.button').on('click', function(it){
        var sidebar;
        it.preventDefault();
        $('#info-panel').hide();
        sidebar = $('.sidebar');
        return sidebar.sidebar('toggle');
      });
    });
    minLatitude = 21.5;
    maxLatitude = 25.5;
    minLongitude = 119.5;
    maxLongitude = 122.5;
    dy = (maxLatitude - minLatitude) / height;
    dx = (maxLongitude - minLongitude) / width;
    proj = function(arg$){
      var x, y;
      x = arg$[0], y = arg$[1];
      return [(x - minLongitude) / dx, height - (y - minLatitude) / dy];
    };
    path = d3.geo.path().projection(proj);
    drawTaiwan = function(countiestopo){
      var layerName, ref$, topoObjects, counties, results$ = [];
      for (layerName in ref$ = countiestopo.objects) {
        topoObjects = ref$[layerName];
        counties = topojson.feature(countiestopo, topoObjects);
        results$.push(g.selectAll('path').data(counties.features).enter().append('path').attr('class', fn$).attr('d', path));
      }
      return results$;
      function fn$(){
        return 'q-9-9';
      }
    };
    ConvertDMSToDD = function(days, minutes, seconds){
      var dd;
      days = +days;
      minutes = +minutes;
      seconds = +seconds;
      dd = minutes / 60 + seconds / (60 * 60);
      return days > 0
        ? days + dd
        : days - dd;
    };
    drawStations = function(stations){
      return g.selectAll('circle').data(stations).enter().append('circle').style('stroke', 'white').style('fill', 'none').attr('r', 2).attr("transform", function(it){
        return "translate(" + proj([+it.lng, +it.lat]) + ")";
      });
    };
    setMetric = function(name){
      var ref$, x$, y$;
      currentMetric = name;
      if (location.pathname.match(/^\/air/)) {
        colorOf = d3.scale.linear().domain((ref$ = metrics[name].domain) != null
          ? ref$
          : [0, 50, 100, 200, 300]).range([d3.hsl(100, 1.0, 0.6), d3.hsl(60, 1.0, 0.6), d3.hsl(30, 1.0, 0.6), d3.hsl(0, 1.0, 0.6), d3.hsl(0, 1.0, 0.1)]);
      } else {
        colorOf = d3.scale.quantile().domain((ref$ = metrics[name].domain) != null
          ? ref$
          : [1, 2, 6, 10, 15, 20, 30, 40, 50, 70, 90, 110, 130, 150, 200, 300]).range(['#c5bec2', '#99feff', '#00ccfc', '#0795fd', '#025ffe', '#3c9700', '#2bfe00', '#fdfe00', '#ffcb00', '#eaa200', '#f30500', '#d60002', '#9e0003', '#9e009d', '#d400d1', '#fa00ff', '#facefb']);
      }
      currentUnit = (ref$ = metrics[name].unit) != null ? ref$ : '';
      addList(stations);
      x$ = legend.selectAll("g.entry").data(colorOf.domain());
      y$ = x$.enter().append('g').attr('class', 'entry');
      y$.append('rect');
      y$.append('text');
      x$.each(function(d, i){
        var x$, y$;
        if (location.pathname.match(/^\/air/)) {
          x$ = d3.select(this);
          x$.select('rect').attr('width', 20).attr('height', 20).attr('x', 30).attr('y', function(){
            return (i + 2) * 30;
          }).style('fill', function(d){
            return colorOf(d);
          });
          x$.select('text').attr('x', 55).attr('y', function(){
            return (i + 2) * 30 + 15;
          }).attr('d', '.35em').text(function(){
            return arguments[0] + currentUnit;
          }).style('fill', '#AAAAAA').style('font-size', '10px');
          return x$;
        } else {
          y$ = d3.select(this);
          y$.select('rect').attr('width', 10).attr('height', 10).attr('x', 30).attr('y', function(){
            return (i + 2) * 10 + 25;
          }).style('fill', function(d){
            return colorOf(d);
          });
          y$.select('text').attr('x', 55).attr('y', function(){
            return (i + 2) * 10 + 35;
          }).attr('d', '.35em').text(function(){
            return arguments[0] + currentUnit;
          }).style('fill', '#AAAAAA').style('font-size', '10px');
          return y$;
        }
      });
      x$.exit().remove();
      return drawHeatmap(stations);
    };
    drawSegment = function(d, i){
      var rawValue, ref$;
      d3.select('#station-name').text(d.name);
      if (epaData[d.name] != null && !isNaN(epaData[d.name][currentMetric])) {
        rawValue = parseInt(epaData[d.name][currentMetric]) + "";
        return updateSevenSegment(repeatString$(" ", 0 > (ref$ = 4 - rawValue.length) ? 0 : ref$) + rawValue);
      } else {
        return updateSevenSegment("----");
      }
    };
    addList = function(stations){
      var list;
      list = d3.select('div.sidebar');
      return list.selectAll('a').data(stations).enter().append('a').attr('class', 'item').text(function(it){
        return it.SiteName;
      }).on('click', function(d, i){
        drawSegment(d, i);
        $('.launch.button').click();
        return $('#main-panel').css('display', 'block');
      });
    };
    epaData = {};
    samples = {};
    distanceSquare = function(arg$, arg1$){
      var x1, y1, x2, y2;
      x1 = arg$[0], y1 = arg$[1];
      x2 = arg1$[0], y2 = arg1$[1];
      return Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2);
    };
    idwTrain = function(samples){
      var sx, sy, sz, i$, len$, s;
      sx = [];
      sy = [];
      sz = [];
      for (i$ = 0, len$ = samples.length; i$ < len$; ++i$) {
        s = samples[i$];
        sx.push(s[0]);
        sy.push(s[1]);
        sz.push(s[2]);
      }
      return kriging.train(sz, sx, sy, "exponential", 0, 100);
    };
    idwPred = function(variogram, point){
      return kriging.predict(point[0], point[1], variogram);
    };
    yPixel = 0;
    plotInterpolatedData = function(ending){
      var steps, starts, res$, i$, to$, ridx$, renderLine;
      yPixel = height;
      steps = 2;
      res$ = [];
      for (i$ = 2, to$ = 2 * (steps - 1); i$ <= to$; i$ += 2) {
        ridx$ = i$;
        res$.push(ridx$);
      }
      starts = res$;
      renderLine = function(){
        var c, variogram, i$, to$, xPixel, y, x, z, ref$;
        c = canvas.node().getContext('2d');
        variogram = idwTrain(samples);
        for (i$ = 0, to$ = width; i$ <= to$; i$ += 2) {
          xPixel = i$;
          y = minLatitude + dy * ((yPixel + zoom.translate()[1] - height) / zoom.scale() + height);
          x = minLongitude + dx * ((xPixel - zoom.translate()[0]) / zoom.scale());
          z = 0 > (ref$ = idwPred(variogram, [x, y])) ? 0 : ref$;
          c.fillStyle = colorOf(z);
          c.fillRect(xPixel, height - yPixel, 2, 2);
        }
        if (yPixel >= 0) {
          yPixel = yPixel - 2 * steps;
          return setTimeout(renderLine, 0);
        } else if (starts.length > 0) {
          yPixel = height - starts.shift();
          return setTimeout(renderLine, 0);
        } else if (ending) {
          return setTimeout(ending, 0);
        }
      };
      return renderLine();
    };
    updateSevenSegment = function(valueString){
      var pins, sevenSegmentCharMap;
      pins = "abcdefg";
      sevenSegmentCharMap = {
        ' ': 0x00,
        '-': 0x40,
        '0': 0x3F,
        '1': 0x06,
        '2': 0x5B,
        '3': 0x4F,
        '4': 0x66,
        '5': 0x6D,
        '6': 0x7D,
        '7': 0x07,
        '8': 0x7F,
        '9': 0x6F
      };
      return d3.selectAll('.seven-segment').data(valueString).each(function(d, i){
        var bite, i$, to$, bit, results$ = [];
        bite = sevenSegmentCharMap[d];
        for (i$ = 0, to$ = pins.length - 1; i$ <= to$; ++i$) {
          i = i$;
          bit = Math.pow(2, i);
          results$.push(d3.select(this).select("." + pins[i]).classed('on', (bit & bite) === bit));
        }
        return results$;
      });
    };
    function piped(url){
      url = replace$.call(url, /^https?:\/\//, '');
      return "https://cors-anywhere.herokuapp.com/" + url;
    }
    drawHeatmap = function(stations){
      var res$, i$, len$, st, val;
      d3.select('#rainfall-timestamp').text(epaData.士林.PublishTime + "");
      d3.select('#station-name').text("已更新");
      updateSevenSegment("    ");
      res$ = [];
      for (i$ = 0, len$ = stations.length; i$ < len$; ++i$) {
        st = stations[i$];
        if (epaData[st.name] != null) {
          val = parseFloat(epaData[st.name][currentMetric]);
          if (isNaN(val)) {
            continue;
          }
          res$.push([+st.lng, +st.lat, val]);
        }
      }
      samples = res$;
      while (samples.length > 100) {
        res$ = [];
        for (i$ = 0, len$ = samples.length; i$ < len$; ++i$) {
          st = samples[i$];
          if (Math.random() > 0.5) {
            res$.push(st);
          }
        }
        samples = res$;
      }
      svg.selectAll('circle').data(stations).style('fill', function(st){
        return '#FFFFFF';
      }).on('mouseover', function(d, i){
        var ref$, x, y, sitecode;
        drawSegment(d, i);
        ref$ = d3.event, x = ref$.clientX, y = ref$.clientY;
        history.style('left', x + 'px').style('top', y + 'px');
        sitecode = d.SiteCode;
        return d3.xhr("http://graphite.gugod.org/render/?_salt=1392034055.328&lineMode=connected&from=-24hours&target=epa.aqx.site_code." + sitecode + ".pm25&format=csv", function(err, req){
          var datum, value, date;
          datum = d3.csv.parseRows(req.responseText, function(arg$){
            var _, date, value;
            _ = arg$[0], date = arg$[1], value = arg$[2];
            return {
              date: date,
              value: parseFloat(value)
            };
          });
          if (!datum.length) {
            return;
          }
          history.chart.load({
            columns: [
              ['pm2.5'].concat((function(){
                var i$, ref$, len$, results$ = [];
                for (i$ = 0, len$ = (ref$ = datum).length; i$ < len$; ++i$) {
                  value = ref$[i$].value;
                  results$.push(value);
                }
                return results$;
              }())), ['x'].concat((function(){
                var i$, ref$, len$, results$ = [];
                for (i$ = 0, len$ = (ref$ = datum).length; i$ < len$; ++i$) {
                  date = ref$[i$].date;
                  results$.push(date);
                }
                return results$;
              }()))
            ]
          });
          return history.chart.resize();
        });
      });
      return plotInterpolatedData();
    };
    setupHistory = function(){
      var chart;
      chart = c3.generate({
        bindto: '#history',
        data: {
          x: 'x',
          x_format: '%Y-%m-%d %H:%M:%S',
          columns: [['x', '2014-01-01 00:00:00'], ['pm2.5', 0]]
        },
        legend: {
          show: false
        },
        axis: {
          x: {
            type: 'timeseries'
          }
        }
      });
      return history.chart = chart;
    };
    aqxCsvUrlWithTime = function(t){
      var year, month, day, hour, min;
      year = t.substr(0, 4);
      month = t.substr(4, 2);
      day = t.substr(6, 2);
      hour = t.substr(8, 2);
      min = t.substr(10, 2);
      return "https://raw.githubusercontent.com/g0v-data/mirror-" + year + "/master/epa/aqx/" + year + "-" + month + "-" + day + "/" + hour + "-" + min + ".csv";
    };
    drawAll = function(_stations, aqx_url){
      var res$, i$, len$, s;
      aqx_url == null && (aqx_url = 'http://g0v-data-mirror.gugod.org/epa/aqx.csv');
      if (location.pathname.match(/^\/air/)) {
        res$ = [];
        for (i$ = 0, len$ = _stations.length; i$ < len$; ++i$) {
          s = _stations[i$];
          s.lng = s.TWD97Lon;
          s.lat = s.TWD97Lat;
          s.name = s.SiteName;
          res$.push(s);
        }
        stations = res$;
        d3.csv(piped(aqx_url), function(it){
          var res$, i$, len$, e;
          res$ = {};
          for (i$ = 0, len$ = it.length; i$ < len$; ++i$) {
            e = it[i$];
            res$[e.SiteName] = e;
          }
          epaData = res$;
          setMetric('PM2.5');
          $('.psi').click(function(){
            return setMetric('PSI');
          });
          $('.pm10').click(function(){
            return setMetric('PM10');
          });
          $('.pm25').click(function(){
            return setMetric('PM2.5');
          });
          return $('.o3').click(function(){
            return setMetric('O3');
          });
        });
      } else {
        stations = _stations;
        d3.json('/rainfall.json', function(it){
          var res$, i$, len$, e;
          res$ = {};
          for (i$ = 0, len$ = it.length; i$ < len$; ++i$) {
            e = it[i$];
            res$[e.name] = e;
          }
          epaData = res$;
          return setMetric('RAIN');
        });
      }
      return drawStations(stations);
    };
    zoom = d3.behavior.zoom().on('zoom', function(){
      g.attr('transform', 'translate(' + d3.event.translate.join(',') + ')scale(' + d3.event.scale + ')');
      g.selectAll('path').attr('d', path.projection(proj));
      return canvas.style('transform-origin', 'top left').style('transform', 'translate(' + (zoom.translate()[0] - canvas.origin[0]) + 'px,' + (zoom.translate()[1] - canvas.origin[1]) + 'px)' + 'scale(' + zoom.scale() / canvas.scale + ')');
    }).on('zoomend', function(){
      var this$ = this;
      canvas = wrapper.insert('canvas', 'canvas').attr('width', width).attr('height', height).style('position', 'absolute');
      canvas.origin = zoom.translate();
      canvas.scale = zoom.scale();
      return plotInterpolatedData(function(){
        return wrapper.selectAll('canvas').data([0]).exit().remove();
      });
    });
    if (location.pathname.match(/^\/air/)) {
      now = new Date().getTime();
      setupHistory();
      return function(done){
        var countiestopo, stations;
        if (localStorage.countiestopo && localStorage.stations) {
          countiestopo = JSON.parse(localStorage.countiestopo);
          stations = JSON.parse(localStorage.stations);
          if (countiestopo.lastUpdated && now - countiestopo.lastUpdated < 86400 * 1000 * 7) {
            return done(countiestopo, stations);
          }
        }
        return d3.json("/twCounty2010.topo.json", function(countiestopo){
          try {
            localStorage.countiestopo = JSON.stringify((countiestopo.lastUpdated = now, countiestopo));
          } catch (e$) {}
          return d3.csv("/epa-site.csv", function(stations){
            try {
              localStorage.stations = JSON.stringify(stations);
            } catch (e$) {}
            return done(countiestopo, stations);
          });
        });
      }(function(countiestopo, stations){
        var matched;
        drawTaiwan(countiestopo);
        if (matched = location.search.match(/[\?\&\;]t=([0-9]+)(?:[^0-9]|$)/)) {
          drawAll(stations, aqxCsvUrlWithTime(matched[1]));
        } else {
          drawAll(stations);
        }
        return svg.call(zoom);
      });
    } else {
      return d3.json("/stations.json", function(stations){
        return drawAll(stations);
      });
    }
  });
  function repeatString$(str, n){
    for (var r = ''; n > 0; (n >>= 1) && (str += str)) if (n & 1) r += str;
    return r;
  }
}).call(this);
