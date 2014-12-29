require! <[influx request]>

epa-aqx-url = 'http://opendata.epa.gov.tw/ws/Data/AQX/?$orderby=SiteName&$skip=0&$top=1000&format=csv'
influx-connection = do
  host: 'influxdb-1.667169fa-pm5.node.tutum.io'
  port: 8086
  database: 'env'
  username: 'g0v'
  password: 'Paefiez8beeGou4i'

client = influx influx-connection

err, resp, body <- request epa-aqx-url
if err
  console.log 'epa-aqx request', err
  return

lines = body.split /[\r\n]+/
fields = lines.shift!.split /,/
  ..shift!
  ..shift!
  ..pop!
textFields = fields.splice 1, 2
points = lines.map (line) ->
  values = line.split /,/
  siteName = values.shift!
  countyName = values.shift!  # unused
  time = new Date values.pop!
  {["epa-aqx.#{textFields[i]}.#siteName", [{value, time}]] for value, i in values.splice 1, 2} <<<
    {["epa-aqx.#{fields[i]}.#siteName", [{value, time}]] for value, i in values.map parseFloat}
.reduce (all, newPoints) ->
  all <<< newPoints
, {}

err <- client.writeSeries points
if err
  console.log 'epa-aqx request', err
