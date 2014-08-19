{parseString} = require 'xml2js'

export function parse-response(body, cb)
  err, {cwbopendata}:result? <- parseString body, {-explicitArray}
  if err
    return cb err

  cb null, cwbopendata
