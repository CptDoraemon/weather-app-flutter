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
      home: Scaffold(
        body: WeatherAppLoader()
      ),
      theme: ThemeData(primaryColor: Colors.white),
    );
  }
}

class WeatherAppLoader extends StatefulWidget {
  _WeatherAppLoaderState createState() => _WeatherAppLoaderState();
}


class _WeatherAppLoaderState extends State<WeatherAppLoader> {
  bool _isLocated = false;
  bool _isWeatherDataRetrieved = false;
  bool _isError = false;
  DateTime _lastLoaded;
  String _errorMessage;
  Map<String, double> _currentLocation;
  WeatherData _weatherData;
  String _locationDescription;

  Widget locatingScene() {
    return Center(
       child: Text('Getting your location...'),
    );
  }
  Widget retrievingWeatherDataScene() {
    return Center(
      child: Text('Retrieving weather data...')
    );
  }
  Widget errorScene() {
    return Center(
      child: Text('error'),
    );
  }
  Widget loadedScene(_weatherData, _locationDescription) {
    return RefreshIndicator(
      key: ValueKey(_lastLoaded),
      child: WeatherApp(_weatherData, _locationDescription),
      onRefresh: _refreshHandler,
    );
  }
  void snackBar(String message) {
    final snackBar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[Text(message)],
      ),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }

  Future<void> _refreshHandler() async {
    DateTime whenRequested = DateTime.now();
    if (whenRequested.difference(_lastLoaded).inSeconds < 10) {
      await Future.delayed(Duration(seconds: 3), () => snackBar('Refresh data loaded :)'));
    } else {
      await _getLocation();
      snackBar('Refresh data loaded');
    }
  }
 Future<void> _getLocation() async {
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
      await _getWeatherData(_currentLocation);
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

  Future<void> _getWeatherData(Map<String, double> location) async {
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
        _lastLoaded = DateTime.now();
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
      loadedScene(_weatherData, _locationDescription);
  }
}

