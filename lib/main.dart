import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'dart:convert';

import './weather-data.dart';
import './weather-app.dart';

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
  String _locationDescription;

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
    try {
      String weatherAPI = 'https://www.xiaoxihome.com/api/weather';
      String locationDescriptionAPI = 'https://www.xiaoxihome.com/api/reversegeocoding';
      final body = jsonEncode({
        'latitude': location['latitude'].toString(),
        'longitude': location['longitude'].toString()
      });

      final weatherRes = await http.post(weatherAPI, headers: {"Content-Type": "application/json"}, body: body);
      final locationDescriptionRes = await http.post(locationDescriptionAPI, headers: {"Content-Type": "application/json"}, body: body);

      print(weatherRes.body);
      Map<String, dynamic> weatherResJson = jsonDecode(weatherRes.body);
      Map<String, dynamic> locationDescriptionResJson = jsonDecode(locationDescriptionRes.body);

      if (weatherResJson['status'] == 'success' && locationDescriptionResJson['status'] == 'success') {
        _weatherData = WeatherData(weatherResJson['data']);
        _locationDescription = locationDescriptionResJson['data'];
        setState(() {
          _isWeatherDataRetrieved = true;
        });
      } else {
        _isError = true;
        _errorMessage = 'Error occured when getting weather data';
      }
    } catch (e) {
      _isError = true;
      _errorMessage = 'Error occured when getting weather data';
      throw(e);
    }

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
      WeatherApp(_weatherData, _locationDescription);
  }
}

