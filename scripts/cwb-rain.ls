require! <[fs request]>
{parseString} = require 'xml2js'

# XXX check last modified
err, {body}?, res <- request 'http://opendata.cwb.gov.tw/opendata/DIV2/O-A0002-001.xml'

err, {cwbopendata}:result <- parseString body, {-explicitArray}

res = for {stationId, locationName, weatherElement} in cwbopendata.location
  values = {[elementName, parse-float elementValue.value] for {elementName, elementValue} in weatherElement}
  {stationId, name: locationName } <<<< values

stations = for {stationId, locationName, lat, lon} in cwbopendata.location
  {stationId, name: locationName, lat, lng:lon}

err <- fs.writeFile 'src/rainfall.json', JSON.stringify(res)

console.log 'rainfall.json saved!'

err <- fs.writeFile 'src/stations.json', JSON.stringify(stations)

console.log 'stations.json saved!'