import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './weather-data.dart';
import './hourly-chart-canvas.dart';

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
  int _hourOffset = 0;
  static int timeOrigin;
  List<dynamic> selectedDataPath; // property chain, int for list, string for map
  final WeatherData weatherData;
  final String locationDescription;

  _WeatherAppState (this.weatherData, this.locationDescription)
      : selectedDataPath = ['currently'] {
    timeOrigin = weatherData.celsius()['currently'].time;
  }

  // only the selected data obj
  WeatherDataObject getSelectedData() {
    dynamic object = getUnitConvertedData();
    for (int i=0; i<selectedDataPath.length; i++) {
      object = object[selectedDataPath[i]];
    }
    // no time needed for daily data
    return object;
  }

  // All the data, unit converted
  Map getUnitConvertedData() {
    return _isCelsius ? weatherData.celsius() : weatherData.fahrenheit();
  }

  void changeSelectedData(List<dynamic> newSelectedDataPath) {
    setState(() {
      selectedDataPath = newSelectedDataPath;
      // offset hourly chart
      if (newSelectedDataPath[0] == 'daily') {
        int targetTime = weatherData.celsius()['daily'][newSelectedDataPath[1]].time;
        int hourDifference = ((targetTime - timeOrigin) / 1000 / 60 / 60).ceil();
        _hourOffset = hourDifference > 0 ? hourDifference : 0;
        print((targetTime - timeOrigin) / 1000 / 60 / 60);
      }
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
            HourlyChart(getUnitConvertedData()['hourly'], _hourOffset),
            DailyChart(getUnitConvertedData()['daily'], changeSelectedData)
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
      padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      child: Column(
        children: [
          Text(locationDescription, style: TextStyle(fontSize: 24.0), textAlign: TextAlign.center,),
          Text('${selectedData.weekdayLong} ${selectedData.timeString}', style: TextStyle(fontWeight: FontWeight.bold)),
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

class HourlyChart extends StatefulWidget {
  final List<WeatherDataObject> hourlyDataList;
  final int _hourOffset;
  HourlyChart(this.hourlyDataList, this._hourOffset);

  @override
  createState() => _HourlyChartState();
}
class _HourlyChartState extends State<HourlyChart> {
  int _chartState = 0;

  void setChartState(int state) {
    setState(() {
      _chartState = state;
    });
  }
  Widget chartSelectorButton(int index, Widget icon) {
    return ButtonTheme(
      minWidth: 20.0,
      height: 20.0,
      child: IconButton(
        onPressed: () => setChartState(index),
        icon: icon,
        color: index == _chartState ? Colors.grey : Colors.grey[300],
        iconSize: 20.0,
      ),
    );
  }
  Widget chartSelector() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          chartSelectorButton(0, Icon(FontAwesomeIcons.thermometerThreeQuarters)),
          chartSelectorButton(1, Icon(FontAwesomeIcons.tint)),
          chartSelectorButton(2, Icon(FontAwesomeIcons.wind)),
        ],
      ),
    );
  }
  Widget chartGenerator(horizontalPadding, hourWidth, Widget wrappedChart) {
    return Container(
        height: 100.0,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Transform.translate(
          offset: Offset(-hourWidth * widget._hourOffset, 0),
          child: wrappedChart,
        )
    );
  }
  Widget temperatureChart() {
    return CustomPaint(
      painter: PrecipitationPainter(widget.hourlyDataList),
    );
  }
  Widget precipitationChart() {
    return Text('Precipitation');
  }
  Widget windChart() {
    return Text('Wind');
  }


  @override
  Widget build(BuildContext context) {
    double horizontalPadding = 10.0;
    double canvasWidth = MediaQuery.of(context).size.width - 2 * horizontalPadding;
    double hourWidth = canvasWidth / 24;

    return Container(
      child: Column(
        children: [
          chartSelector(),
          _chartState == 0 ? chartGenerator(horizontalPadding, hourWidth, temperatureChart()) :
          _chartState == 1 ? chartGenerator(horizontalPadding, hourWidth, precipitationChart()) :
          chartGenerator(horizontalPadding, hourWidth, windChart()),
        ],
      ),
    );
  }
}

class DailyChart extends StatelessWidget {
  final List<WeatherDataObject> dailyDataList;
  final Function selectedDataSwitcher;
  DailyChart(this.dailyDataList, this.selectedDataSwitcher);

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
  Widget weatherIcon(String iconName) {
    return SvgPicture.asset(
        'assets/weather-icons/$iconName.svg',
        color: Colors.red,
        semanticsLabel: iconName
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
  Widget dayGraphWidget(WeatherDataObject dailyDataObject, int index) {
    List<dynamic> pathList = ['daily', index];
    return ButtonTheme(
      minWidth: 5.0,
      height: 80.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      child: FlatButton(
        onPressed: () => selectedDataSwitcher(pathList),
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            dayGraphColumnTextItemContainer(Text(dailyDataObject.weekdayShort)),
            dayGraphColumnImageItemContainer(weatherIcon(dailyDataObject.icon)),
            dayGraphColumnTextItemContainer(temperatureHighNLow(dailyDataObject.temperatureHigh.toString(), dailyDataObject.temperatureLow.toString())),
          ],
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150.0,
      child: ListView.builder(
        itemCount: dailyDataList.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return dayGraphWidget(dailyDataList[index], index);
        },
      ),
    );
  }
}