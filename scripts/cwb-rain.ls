require! <[fs request]>
{parseString} = require 'xml2js'

# XXX check last modified
err, {body}?, res <- request 'http://opendata.cwb.gov.tw/opendata/DIV2/O-A0002-001.xml'

err, {cwbopendata}:result <- parseString body, {-explicitArray}

res = for {stationId, locationName, weatherElement} in cwbopendata.location
	values = {[elementName, parse-float elementValue.value] for {elementName, elementValue} in weatherElement}
	{stationId, locationName, values}

console.log res
