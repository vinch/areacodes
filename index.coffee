# initialization

fs = require 'fs'
http = require 'http'
express = require 'express'
ca = require 'connect-assets'
request = require 'request'
log = require('logule').init(module)

app = express()
server = http.createServer app

# error handling

process.on 'uncaughtException', (err) ->
  log.error err.stack

# configuration

app.configure ->
  app.set 'views', __dirname + '/app/views'
  app.set 'view engine', 'jade'
  app.use express.urlencoded()
  app.use express.json()
  app.use express.cookieParser()
  app.use express.favicon __dirname + '/public/img/favicon.ico'
  app.use express.static __dirname + '/public'
  app.use ca {
    src: 'app/assets'
    buildDir: 'public'
  }

app.configure 'development', ->
  app.set 'BASE_URL', 'http://localhost:3567'

app.configure 'production', ->
  app.set 'BASE_URL', 'http://areacodes.herokuapp.com'

# middlewares

logRequest = (req, res, next) ->
  log.info req.method + ' ' + req.url
  next()

# functions

distance = (lat1, lon1, lat2, lon2) ->
  R = 3961 # Earth radius in miles
  dLat = deg2rad(lat2-lat1)
  dLon = deg2rad(lon2-lon1) 
  a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon/2) * Math.sin(dLon/2)
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)) 
  d = R * c
  return d

deg2rad = (deg) ->
  return deg * (Math.PI/180)

# routes

app.all '*', logRequest, (req, res, next) ->
  next()

app.get '/', (req, res) ->
  res.render 'areacodes'

app.get '/cities', (req, res) ->
  lat = req.query.lat || 37.774929
  lng = req.query.lng || -122.419416
  limit = req.query.limit  || 50
  fs.readFile 'data/cities.json', 'utf8', (err, data) ->
    result = []
    for city in JSON.parse(data)
      city.distance = distance(city.location.lat, city.location.lng, lat, lng)
      result.push city
    (result.sort (a, b) -> return a.distance - b.distance)
    res.send result.slice(0, limit)

app.all '*', (req, res) ->
  res.redirect '/'

# server creation

server.listen process.env.PORT ? '3567', ->
  log.info 'Express server listening on port ' + server.address().port + ' in ' + app.settings.env + ' mode'