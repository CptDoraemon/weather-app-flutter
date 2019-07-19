export 'weather-data.dart';

class WeatherData {
  WeatherDataObject currentlyCelsius;
  WeatherDataObject currentlyFahrenheit;

  List<WeatherDataObject> hourlyCelsius = [];
  List<WeatherDataObject> hourlyFahrenheit = [];

  List<WeatherDataObject> dailyCelsius = [];
  List<WeatherDataObject> dailyFahrenheit = [];


  WeatherData(Map<String, dynamic>  json) {
    this.currentlyCelsius = WeatherDataObject.celsius(json['currently']);
    this.currentlyFahrenheit = WeatherDataObject.fahrenheit(json['currently']);

    List<dynamic> hourly = json['hourly']['data'];
    List<dynamic> daily = json['daily']['data'];
    for (int i=0; i<hourly.length; i++) {
      this.hourlyCelsius.add(WeatherDataObject.celsius(hourly[i]));
      this.hourlyFahrenheit.add(WeatherDataObject.fahrenheit(hourly[i]));
    }
    for (int i=0; i<daily.length; i++) {
      this.dailyCelsius.add(WeatherDataObject.celsius(daily[i]));
      this.dailyFahrenheit.add(WeatherDataObject.fahrenheit(daily[i]));
    }
  }

  celsius() {
    return {
      'currently' : currentlyCelsius,
      'hourly' : hourlyCelsius,
      'daily': dailyCelsius
    };
  }

  fahrenheit() {
    return {
      'currently' : currentlyFahrenheit,
      'hourly' : hourlyFahrenheit,
      'daily': dailyFahrenheit
    };
  }
}

class WeatherDataObject {
  static List<String> weekdayLongList= ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static List<String> weekdayShortList= ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final String summary;
  final String icon;
  final int temperature;
  final int temperatureHigh;
  final int temperatureLow;
  final int precipitation;
  final int windBearing;
  final int windSpeed;
  final int humidity;

  String weekdayLong;
  String weekdayShort;
  String hour;
  String minute;
  int time;



  WeatherDataObject.fahrenheit(Map<String, dynamic> json)
      : summary = json['summary'],
        icon = json['icon'],
        temperature = json['temperature'] == null ? json['temperatureHigh'].round() : json['temperature'].round(),
        temperatureHigh = json['temperatureHigh'] == null ? 0 : fToC(json['temperatureHigh'].round()),
        temperatureLow = json['temperatureLow'] == null ? 0 : fToC(json['temperatureLow'].round()),
        precipitation = (json['precipProbability'] * 100).round(),
        windBearing = json['windBearing'].round(),
        windSpeed = json['windSpeed'].round(),
        humidity = (json['humidity'] * 100).round(){
    time = json['time'] * 1000;
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
    weekdayLong = weekdayLongList[date.weekday - 1];
    weekdayShort = weekdayShortList[date.weekday - 1];
    hour = date.hour < 10 ? '0${date.hour}' : date.hour.toString();
    minute = date.minute < 10 ? '0${date.minute}' : date.minute.toString();
  }

//  WeatherDataObject.celsius(Map<String, dynamic> json)
//      : summary = json['summary'],
//        icon = json['icon'],
//        weekdayLong = weekdayLongList[DateTime(json['time']).weekday - 1],
//        weekdayShort = weekdayShortList[DateTime(json['time']).weekday - 1],
//        hour = DateTime(json['time']).hour < 10 ? '0${DateTime(json['time']).hour}' : DateTime(json['time']).hour.toString(),
//        minute = DateTime(json['time']).minute < 10 ? '0${DateTime(json['time']).minute}' : DateTime(json['time']).minute.toString(),
//        temperature = json['temperature'] == null ? fToC(json['temperatureHigh']) : fToC(json['temperature']),
//        temperatureHigh = json['temperatureHigh'] == null ? 0 : fToC(json['temperatureHigh'].round()),
//        temperatureLow = json['temperatureLow'] == null ? 0 : fToC(json['temperatureLow'].round()),
//        precipitation = (json['precipProbability'] * 100).round(),
//        windBearing = json['windBearing'].round(),
//        windSpeed = mphToKmh(json['windSpeed']),
//        humidity = (json['humidity'] * 100).round(),
//        time = json['time'] * 1000;
  WeatherDataObject.celsius(Map<String, dynamic> json)
      : summary = json['summary'],
        icon = json['icon'],
        temperature = json['temperature'] == null ? fToC(json['temperatureHigh']) : fToC(json['temperature']),
        temperatureHigh = json['temperatureHigh'] == null ? 0 : fToC(json['temperatureHigh'].round()),
        temperatureLow = json['temperatureLow'] == null ? 0 : fToC(json['temperatureLow'].round()),
        precipitation = (json['precipProbability'] * 100).round(),
        windBearing = json['windBearing'].round(),
        windSpeed = mphToKmh(json['windSpeed']),
        humidity = (json['humidity'] * 100).round(){
    time = json['time'] * 1000;
    DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
    weekdayLong = weekdayLongList[date.weekday - 1];
    weekdayShort = weekdayShortList[date.weekday - 1];
    hour = date.hour < 10 ? '0${date.hour}' : date.hour.toString();
    minute = date.minute < 10 ? '0${date.minute}' : date.minute.toString();
  }

  static int fToC(f) {
    double c = (f - 32) * 5 / 9;
    return c.round();
  }
  static int mphToKmh(mph) {
    double kmh =  mph * 1.609;
    return kmh.round();
  }
}