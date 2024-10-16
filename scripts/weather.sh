#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

fahrenheit=$1
show_location=$2
fixedlocation=$3
addweatherspace=$4

# Base URL of the weather API
BASE_API_URL="https://api.merrysky.net/weather"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it to parse JSON."
    exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Please install it to fetch data from the API."
    exit 1
fi

construct_api_url() {
    if [[ ! -z "$fixedlocation" ]]; then
        echo "${BASE_API_URL}?q=${fixedlocation// /%20}&source=pirateweather"
    else
        echo "${BASE_API_URL}?source=pirateweather"
    fi
}

display_location()
{
  if $show_location && [[ ! -z "$fixedlocation" ]]; then
    echo "$fixedlocation"
  elif $show_location; then
    echo "$(curl -s "$(construct_api_url)" | jq -r '.merry.location.name')"
  else
    echo ''
  fi
}

fetch_weather_information()
{
  curl -s "$(construct_api_url)"
}

display_weather()
{
  weather_information=$(fetch_weather_information)

  # Extract current temperature and weather condition
  if $fahrenheit; then
    temperature=$(echo "$weather_information" | jq -r '(.currently.temperature * 9/5 + 32) | round | tostring + "°F"')
  else
    temperature=$(echo "$weather_information" | jq -r '.currently.temperature | round | tostring + "°C"')
  fi

  weather_condition=$(echo "$weather_information" | jq -r '.currently.summary')
  unicode=$(forecast_unicode "$weather_condition")

  echo "$unicode $temperature"
}

forecast_unicode()
{
  weather_condition=$(echo "$1" | awk '{print tolower($0)}')

  if [[ $weather_condition =~ 'snow' ]]; then
    if [[ $addweatherspace == "true" ]]; then
      echo '❄ '
    else
      echo '❄'
    fi
  elif [[ (($weather_condition =~ 'rain') || ($weather_condition =~ 'shower')) ]]; then
    if [[ $addweatherspace == "true" ]]; then
      echo '☂ '
    else
      echo '☂'
    fi
  elif [[ (($weather_condition =~ 'overcast') || ($weather_condition =~ 'cloud')) ]]; then
    if [[ $addweatherspace == "true" ]]; then
      echo '☁ '
    else
      echo '☁'
    fi
  elif [[ $weather_condition = 'NA' ]]; then
    echo ''
  else
    if [[ $addweatherspace == "true" ]]; then
      echo '☀ '
    else
      echo '☀'
    fi
  fi
}

main()
{
  API_URL=$(construct_api_url)
  if echo "$weather_data" | jq empty > /dev/null 2>&1; then
    echo "$(display_weather) $(display_location)"
  else
    echo "Weather Unavailable"
  fi
}

#run main driver program
main
