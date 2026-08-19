## weather — current conditions and forecast for any place on Earth.
##
## Data: Open-Meteo (https://open-meteo.com), free for non-commercial use,
## no API key. Two-step lookup: geocode the place name, then fetch weather.

import std/[httpclient, json, strutils, uri]
import niffler/sdk

let comp = newComponent("weather", "0.1.0")

proc client(): HttpClient =
  newHttpClient("niffler-weather/0.1", timeout = 15_000)

proc geocode(place: string): JsonNode =
  ## First hit of Open-Meteo's geocoding API for a place name.
  let c = client()
  defer: c.close()
  let resp = c.getContent("https://geocoding-api.open-meteo.com/v1/search?name=" &
    encodeUrl(place) & "&count=1&language=en&format=json").parseJson()
  let hits = resp{"results"}
  if hits == nil or hits.len == 0:
    raise newException(ValueError, "place not found: " & place)
  result = hits[0]

proc describe(code: int): string =
  ## WMO weather interpretation code → human text.
  case code
  of 0: "clear sky"
  of 1: "mainly clear"
  of 2: "partly cloudy"
  of 3: "overcast"
  of 45, 48: "fog"
  of 51..55: "drizzle"
  of 56, 57: "freezing drizzle"
  of 61..65: "rain"
  of 66, 67: "freezing rain"
  of 71..77: "snowfall"
  of 80..82: "rain showers"
  of 85, 86: "snow showers"
  of 95: "thunderstorm"
  of 96, 99: "thunderstorm with hail"
  else: "WMO weather code " & $code

comp.tool:
  proc weather_current(place: string): JsonNode =
    ## Current weather conditions at a place anywhere in the world:
    ## temperature, feels-like, humidity, wind and a plain-text condition
    ## summary. Use for "what's the weather in X right now?" questions.
    ## - place: A place name, e.g. "Berlin", "Gothenburg" or "New York"
    let geo = geocode(place)
    let lat = geo{"latitude"}.getFloat()
    let lon = geo{"longitude"}.getFloat()
    let here = geo{"name"}.getStr("") & ", " & geo{"country"}.getStr("")
    let c = client()
    defer: c.close()
    let resp = c.getContent("https://api.open-meteo.com/v1/forecast?latitude=" &
      $lat & "&longitude=" & $lon &
      "&current=temperature_2m,relative_humidity_2m,apparent_temperature," &
      "weather_code,wind_speed_10m&wind_speed_unit=kmh&timezone=auto").parseJson()
    let cur = resp{"current"}
    let code = cur{"weather_code"}.getInt(0)
    return %*{"place": here,
              "temperatureC": cur{"temperature_2m"}.getFloat(),
              "feelsLikeC": cur{"apparent_temperature"}.getFloat(),
              "humidityPct": cur{"relative_humidity_2m"}.getInt(),
              "windKmh": cur{"wind_speed_10m"}.getFloat(),
              "conditions": describe(code),
              "observedAt": cur{"time"}.getStr("")}

comp.tool:
  proc weather_forecast(place: string, days: int = 3): JsonNode =
    ## Daily weather forecast at a place: date, min/max temperature, rain
    ## probability and a plain-text condition summary per day. Use for
    ## "will it rain in X this week?" or "weekend weather" questions.
    ## - place: A place name, e.g. "Tokyo"
    ## - days: Number of days to forecast (1..16, default 3)
    let n = clamp(days, 1, 16)
    let geo = geocode(place)
    let lat = geo{"latitude"}.getFloat()
    let lon = geo{"longitude"}.getFloat()
    let here = geo{"name"}.getStr("") & ", " & geo{"country"}.getStr("")
    let c = client()
    defer: c.close()
    let resp = c.getContent("https://api.open-meteo.com/v1/forecast?latitude=" &
      $lat & "&longitude=" & $lon &
      "&daily=weather_code,temperature_2m_max,temperature_2m_min," &
      "precipitation_probability_max&forecast_days=" & $n &
      "&timezone=auto").parseJson()
    let daily = resp{"daily"}
    var daysJson = newJArray()
    for i in 0 ..< daily{"time"}.len:
      daysJson.add(%*{"date": daily{"time"}[i].getStr(""),
                      "minC": daily{"temperature_2m_min"}[i].getFloat(),
                      "maxC": daily{"temperature_2m_max"}[i].getFloat(),
                      "rainChancePct": daily{"precipitation_probability_max"}[i].getInt(),
                      "conditions": describe(daily{"weather_code"}[i].getInt(0))})
    return %*{"place": here, "forecast": daysJson}

comp.run()
