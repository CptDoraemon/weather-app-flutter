import 'package:flutter/material.dart';
import './weather-data.dart';
import "package:charcode/charcode.dart";

export 'weather-app.dart';

class WeatherApp extends StatefulWidget {
  final WeatherData weatherData;
  final String locationDescription;
  WeatherApp (this.weatherData, this.locationDescription);

  @override
  State<StatefulWidget> createState() => _WeatherAppState(weatherData, locationDescription);
}

class _WeatherAppState extends State<WeatherApp>{
  bool _isCelsius = true;
  List<dynamic> selectedDataPath; // property chain, int for list, string for map
  final WeatherData weatherData;
  final String locationDescription;

  // only the selected data obj
  WeatherDataObject getSelectedData() {
    dynamic object = getUnitConvertedData();
    for (int i=0; i<selectedDataPath.length; i++) {
      object = object[selectedDataPath[i]];
    }
    return object;
  }

  // All the data, unit converted
  Map getUnitConvertedData() {
    return _isCelsius ? weatherData.celsius() : weatherData.fahrenheit();
  }

  _WeatherAppState (this.weatherData, this.locationDescription)
    : selectedDataPath = ['currently'];

  void changeSelectedData(List<String> newSelectedDataPath) {
    setState(() {
      selectedDataPath = newSelectedDataPath;
    });
  }

  void toggleUnit(bool isChangingToCelsius) {
    setState(() {
      _isCelsius = isChangingToCelsius;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
          children: [
            Header(getSelectedData(), locationDescription),
            Summary(getSelectedData(), toggleUnit, _isCelsius),
            HourlyChart(),
            DailyChart(getUnitConvertedData()['daily'])
          ],
        )
    );
  }
}

class Header extends StatelessWidget {
  final WeatherDataObject selectedData;
  final String locationDescription;
  Header(this.selectedData, this.locationDescription);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Text(locationDescription, style: TextStyle(fontSize: 24.0)),
          Text('${selectedData.weekdayLong} ${selectedData.hour}:${selectedData.minute}'),
          Text(selectedData.summary)
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }
}

class Summary extends StatelessWidget {
  final WeatherDataObject selectedData;
  final Function unitSwitcher;
  final bool _isCelsius;
  Summary(this.selectedData, this.unitSwitcher, this._isCelsius);

  Widget unitSwitcherWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ButtonTheme(
          minWidth: 15.0,
          height: 15.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          child: FlatButton(
            onPressed: () => unitSwitcher(true),
            padding: EdgeInsets.all(15.0),
            textColor: _isCelsius ? Colors.black : Colors.grey[400],
            child: Text('\u2103'), // c
          ),
        ),
        Text('|'),
        ButtonTheme(
            minWidth: 15.0,
            height: 15.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
            child: FlatButton(
              onPressed: () => unitSwitcher(false),
              padding: EdgeInsets.all(15.0),
              textColor: !_isCelsius ? Colors.black : Colors.grey[400],
              child: Text('\u2109'), //f
            )
        ),
      ],
    );
  }
  Widget temperatureWidget() {
    return Stack(
      children: [
        Center(
          child: Text(selectedData.temperature.toString(), style: TextStyle(fontSize: 72.0))
        ),
        Positioned(
          child: unitSwitcherWidget(),
          left: 180.0,
          right: 0,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          temperatureWidget(),
          Text('Precipitation: ${selectedData.precipitation}%'),
//          Text('Humidity: ${selectedData.humidity}%'),
          Text('Wind: ${selectedData.windSpeed} ${_isCelsius ? 'km/h' : 'mph'}'),
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }
}
class HourlyChart extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Text('HourlyChart');
  }
}
class DailyChart extends StatelessWidget {
  final List<WeatherDataObject> dailyDataList;
  DailyChart(this.dailyDataList);

  Widget temperatureHighNLow(String temperatureHigh, String temperatureLow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$temperatureHigh\u00B0'),
        Text(' '),
        Text('$temperatureLow\u00B0', style: TextStyle(color: Colors.grey),),
      ],
    );
  }
  Widget dayGraphColumnTextItemContainer(Widget wrappedWidget) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: wrappedWidget,
    );
  }
  Widget dayGraphColumnImageItemContainer(Widget wrappedWidget) {
    return Container(
      height: 50.0,
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: wrappedWidget,
    );
  }
  Widget dayGraphWidget(WeatherDataObject dailyDataObject) {
    return  Container(
      width: 80.0,
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            dayGraphColumnTextItemContainer(Text(dailyDataObject.weekdayShort)),
            dayGraphColumnImageItemContainer(Text(dailyDataObject.icon)),
            dayGraphColumnTextItemContainer(temperatureHighNLow(dailyDataObject.temperatureHigh.toString(), dailyDataObject.temperatureLow.toString())),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      child: ListView.builder(
        itemCount: dailyDataList.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return dayGraphWidget(dailyDataList[index]);
        },
      ),
    );
  }
}