require! <[fs request minimist influx async]>
{parse-response} = require './cwb.js'

{stations,influx-host,influx-db,influx-user,influx-pass}:argv = minimist process.argv.slice 2

if influx-host
  client = influx do
    host : influx-host
    username : influx-user
    password : influx-pass
    database : influx-db

function get-rain(opts, cb)
  # XXX check last modified
  headers = {}
  #headers['if-none-match'] = opts.etag if opts.etag
  headers['if-modified-since'] = opts.last-modified if opts.last-modified
  err, {body,status-code}:res? <- request {url: 'http://opendata.cwb.gov.tw/opendata/DIV2/O-A0002-001.xml', headers}
  if err
    console.log \err, err res
    return cb null
  return cb null if status-code is 304
  console.log res.headers, res.status-code

  err, cwbopendata <- parse-response body
  if err
    console.log \xmlerr, err, res
    return cb null
  if res.headers['last-modified']
    opts.last-modified = that
  cb <| for {stationId, locationName, weatherElement, time, lat, lon} in cwbopendata.location
    values = {[elementName, parse-float elementValue.value] for {elementName, elementValue} in weatherElement}
    {stationId, locationName, values, lat, lon, time: new Date time.obsTime .getTime!}

if stations
  do
    res <- get-rain {}
    stations = for {stationId, locationName, lat, lon} in res
      {stationId, name: locationName, lat, lng: lon}
    err <- fs.writeFile 'src/stations.json', JSON.stringify stations
    rainfall = for {stationId, values} in res
      {stationId} <<< values
    err <- fs.writeFile 'src/rainfall.json', JSON.stringify rainfall
  return

var last-time
err, res <- client.query "select * from rain where time > now() - 24h limit 1"
last-time := res?0?points.0.0
console.log \last last-time

opts = {etag: '"ec16-149a21-5009ae1a1ee83"', last-modified: 'Thu, 14 Aug 2014 19:24:02 GMT'}

function doit(cb)
  res <- get-rain opts
  unless res
    console.log \empty
    return cb!
  console.log res.0.time
  if res.0.time <= last-time
    return cb!
  last-time := res.0.time
  console.log \inserting
  <- client.write-points 'rain', res.map (station) ->
    {station.time, station.stationId} <<< station.values{MIN_10,HOUR_24,NOW}
  console.log \inserted
  cb!
  #console.log opts
  #console.log res



cb = ->
  <- set-timeout _, 240s * 1000ms
  console.log \again!
  doit cb

doit cb

function writeIt(res, cwbopendata)
  stations = for {stationId, locationName, lat, lon} in cwbopendata.location
    {stationId, name: locationName, lat, lng:lon}

  err <- fs.writeFile 'src/rainfall.json', JSON.stringify(res)

  console.log 'rainfall.json saved!'

  err <- fs.writeFile 'src/stations.json', JSON.stringify(stations)

  console.log 'stations.json saved!'

