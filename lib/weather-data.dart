//class WeatherData {
//  final Map<String, dynamic> inputData;
//  Map<String, dynamic> currentlyFahrenheit;
//
//  WeatherData(this.inputData);
//}
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
    for (var i=0; i<hourly.length; i++) {
      this.hourlyCelsius.add(WeatherDataObject.celsius(hourly[i]));
      this.hourlyFahrenheit.add(WeatherDataObject.fahrenheit(hourly[i]));
    }
    for (var i=0; i<daily.length; i++) {
      this.dailyCelsius.add(WeatherDataObject.celsius(daily[i]));
      this.dailyFahrenheit.add(WeatherDataObject.fahrenheit(daily[i]));
    }
  }
}

class WeatherDataObject {
  final String summary;
  final String icon;
  final int temperature;
  final int precipitation;
  final int windBearing;
  final int windSpeed;
  final int time;



  WeatherDataObject.fahrenheit(Map<String, dynamic> json)
      : summary = json['summary'],
        icon = json['icon'],
        temperature = json['temperature'] == null ? json['temperatureHigh'].round() : json['temperature'].round(),
        precipitation = (json['precipProbability'] * 100).round(),
        windBearing = json['windBearing'].round(),
        windSpeed = json['windSpeed'].round(),
        time = json['time'];

  WeatherDataObject.celsius(Map<String, dynamic> json)
      : summary = json['summary'],
        icon = json['icon'],
        temperature = json['temperature'] == null ? fToC(json['temperatureHigh']) : fToC(json['temperature']),
        precipitation = (json['precipProbability'] * 100).round(),
        windBearing = json['windBearing'].round(),
        windSpeed = mphToKmh(json['windSpeed']),
        time = json['time'];

  static int fToC(f) {
    double c = (f - 32) * 5 / 9;
    return c.round();
  }
  static int mphToKmh(mph) {
    double kmh =  mph * 1.609;
    return kmh.round();
  }
}