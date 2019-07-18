import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'dart:convert';

import './weather-data.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather by Xiaoxihome',
      home: Loader(),
      theme: ThemeData(primaryColor: Colors.white),
    );
  }
}

class Loader extends StatefulWidget {
  _LoaderState createState() => _LoaderState();
}


class _LoaderState extends State<Loader> {
  bool _isLocated = false;
  bool _isWeatherDataRetrieved = false;
  bool _isError = false;
  String _errorMessage;
  Map<String, double> _currentLocation;
  WeatherData _weatherData;

  Widget locatingScene() {
    return Scaffold(
        body: Center(
            child: Text('Getting your location...'),
          )
        );
  }
  Widget retrievingWeatherDataScene() {
    return Scaffold(
        body: Center(
          child: Text('Retrieving weather data...'),
        )
    );
  }
  Widget errorScene() {
    return Scaffold(
        body: Center(
          child: Text('error'),
        )
    );
  }

 void _getLocation() async {
    var location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      setState(() {
        _isLocated = true;
        _currentLocation = {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude
        };
      });
      _getWeatherData(_currentLocation);
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'We had a problem to get your location';
        _currentLocation = {
          'latitude': 43.6532,
          'longitude': 79.3832
        };
      });
    }
  }

  void _getWeatherData(Map<String, double> location) async {
    String url = 'https://www.xiaoxihome.com/api/weather';
    final body = jsonEncode({
      'latitude': location['latitude'].toString(),
      'longitude': location['longitude'].toString()
    });
    final res = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
    Map<String, dynamic> rawData = jsonDecode(res.body)['data'];
    _weatherData = WeatherData(rawData);
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return
      !_isLocated ? locatingScene() :
      !_isWeatherDataRetrieved ? retrievingWeatherDataScene() :
      _isError ? errorScene() :
      WeatherApp();
  }
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Text('loaded'),
        )
    );
  }
}

