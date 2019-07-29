import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'dart:convert';

import './weather-data.dart';
import './hourly-chart-canvas.dart';
import './local-storage.dart';

export 'weather-app.dart';

// WeatherAppLoader -> WeatherApp -> [Header, Summary, hourlyChart, dailyGraph]

class WeatherAppLoader extends StatefulWidget {
  final double longitude;
  final double latitude;
  WeatherAppLoader(this.longitude, this.latitude);

  _WeatherAppLoaderState createState() => _WeatherAppLoaderState();
}

class _WeatherAppLoaderState extends State<WeatherAppLoader> with AutomaticKeepAliveClientMixin<WeatherAppLoader>{
  bool _isLocated = false;
  bool _isWeatherDataRetrieved = false;
  bool _isError = false;
  DateTime _lastLoaded;
  String _errorMessage;
  Map<String, double> _currentLocation;
  WeatherData _weatherData;
  String _locationDescription;

  @override
  bool get wantKeepAlive => true;

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
      await Future.delayed(Duration(seconds: 3), () => snackBar('Refreshed data loaded :)'));
    } else {
      await _getLocation();
      snackBar('Refreshed data loaded');
    }
  }
  Future<void> _getLocation() async {
    if (widget.latitude == null || widget.longitude == null) {
      // need GPS location
      var location = Location();
      try {
        LocationData currentLocation = await location.getLocation();
        if (mounted) setState(() {
          _isLocated = true;
          _currentLocation = {
            'latitude': currentLocation.latitude,
            'longitude': currentLocation.longitude
          };
        });
        await _getWeatherData(_currentLocation);
      } catch (e) {
        if (mounted) setState(() {
          _isError = true;
          _errorMessage = 'We had a problem to get your location';
          _currentLocation = {
            'latitude': 43.6532,
            'longitude': 79.3832
          };
        });
      }
    } else {
      // location got from search
      if (mounted) setState(() {
        _isLocated = true;
        _currentLocation = {
          'latitude': widget.latitude,
          'longitude': widget.longitude
        };
      });
      await _getWeatherData(_currentLocation);
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

      Map<String, dynamic> weatherResJson = jsonDecode(weatherRes.body);
      Map<String, dynamic> locationDescriptionResJson = jsonDecode(locationDescriptionRes.body);

      if (weatherResJson['status'] == 'success' && locationDescriptionResJson['status'] == 'success') {
        _weatherData = WeatherData(weatherResJson['data']);
        _locationDescription = locationDescriptionResJson['data'];
        _lastLoaded = DateTime.now();
        if (mounted) setState(() {
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
    super.build(null);
    return
      !_isLocated ? locatingScene() :
      !_isWeatherDataRetrieved ? retrievingWeatherDataScene() :
      _isError ? errorScene() :
      loadedScene(_weatherData, _locationDescription);
  }
}

class WeatherApp extends StatefulWidget {
  final WeatherData weatherData;
  final String locationDescription;
  WeatherApp (this.weatherData, this.locationDescription);

  @override
  State<StatefulWidget> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp>{
  bool _isCelsius = true;
  int _hourOffset = 0;
  int timeOrigin;
  int timeOriginHour;
  LocalStorage _localStorage = LocalStorage();
  List<dynamic> selectedDataPath = ['currently']; // property chain, int for list, string for map

  @override
  void initState() {
    super.initState();
    timeOrigin = widget.weatherData.celsius()['currently'].time;
    timeOriginHour = DateTime.fromMillisecondsSinceEpoch(timeOrigin).hour;
    _localStorage.init((){
      setState(() {
        _isCelsius = _localStorage.getIsCelsius();
      });
    });
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
    return _isCelsius ? widget.weatherData.celsius() : widget.weatherData.fahrenheit();
  }

  void changeSelectedData(List<dynamic> newSelectedDataPath) {
    setState(() {
      selectedDataPath = newSelectedDataPath;
      // offset hourly chart
      if (newSelectedDataPath[0] == 'daily') {
        // resetting if the first day graph is selected
        _hourOffset = newSelectedDataPath[1] == 0 ? 0 : 24 - timeOriginHour + (newSelectedDataPath[1] - 1) * 24;
      }
    });
  }

  void toggleUnit() {
    setState(() {
      _localStorage.toggleIsCelsius();
      _isCelsius = _localStorage.getIsCelsius();
    });
  }

  Widget sectionWrapper(Widget wrappedSection) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: wrappedSection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        sectionWrapper(Header(getSelectedData(), widget.locationDescription)),
        sectionWrapper(Summary(getSelectedData(), toggleUnit, _isCelsius)),
        sectionWrapper(HourlyChart(getUnitConvertedData()['hourly'], _hourOffset, _isCelsius, changeSelectedData, selectedDataPath)),
        sectionWrapper(DailyChart(getUnitConvertedData()['daily'], changeSelectedData))
      ],
    );
  }
}

class Header extends StatelessWidget {
  final WeatherDataObject selectedData;
  final String locationDescription;
  Header(this.selectedData, this.locationDescription);

  Widget textWrapper(Widget wrappedText) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: wrappedText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        textWrapper(Text(locationDescription, style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, height: 1.1), textAlign: TextAlign.center)),
        textWrapper(Text('${selectedData.weekdayLong} ${selectedData.timeString}', style: TextStyle(fontSize: 20.0, height: 1.1))),
        textWrapper(Text(selectedData.summary, style: TextStyle(height: 1.2)))
      ],
      crossAxisAlignment: CrossAxisAlignment.center,
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
            onPressed: () => unitSwitcher(),
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
              onPressed: () => unitSwitcher(),
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
          child: Text(selectedData.temperature.toString(), style: TextStyle(fontSize: 100.0, fontWeight: FontWeight.normal))
        ),
        Positioned(
          child: unitSwitcherWidget(),
          left: 220.0,
          right: 0,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(height: 1.2);
    return Column(
        children: [
          temperatureWidget(),
          Text('Precipitation: ${selectedData.precipitation}%', style: textStyle),
          Text('Humidity: ${selectedData.humidity}%', style: textStyle),
          Text('Wind: ${selectedData.windSpeed} ${_isCelsius ? 'km/h' : 'mph'}', style: textStyle),
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
      );
  }
}

class HourlyChart extends StatefulWidget {
  final List<WeatherDataObject> hourlyDataList;
  final int _hourOffset;
  final bool _isCelsius;
  final Function changeSelectedData;
  final List<dynamic> selectedDataPath;
  HourlyChart(this.hourlyDataList, this._hourOffset, this._isCelsius, this.changeSelectedData, this.selectedDataPath);

  @override
  createState() => _HourlyChartState();
}
class _HourlyChartState extends State<HourlyChart> with TickerProviderStateMixin{
  int _chartState = 0;
//  // explicit animation
//  double _lastHourOffset = 0;
//  Animation<double> animation;
//  AnimationController controller;
//  @override
//  void didUpdateWidget(Widget oldWidget) {
//    super.didUpdateWidget(oldWidget);
//    controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
//    animation = Tween<double>(begin:_lastHourOffset, end: widget._hourOffset * 1.0).animate(controller)
//    ..addListener(() {
//      setState(() {
//
//      });
//    })
//    ..addStatusListener((state) {
//      if (state == AnimationStatus.completed) {
//        _lastHourOffset = widget._hourOffset * 1.0;
//      }
//    });
//    controller.forward();
//  }
//  @override
//  void dispose() {
//    controller.dispose();
//    super.dispose();
//  }
//

  void setChartState(int state) {
    setState(() {
      _chartState = state;
    });
  }

  void canvasTapHandler(TapDownDetails details, double padding) {
    final RenderBox referenceBox = context.findRenderObject();
    final Offset offset = referenceBox.globalToLocal(details.globalPosition);
    final double hoursBlockWidth = (referenceBox.size.width - padding * 2) / 24;
    final double touchX = offset.dx - padding;
    final int whichBlockTapped = touchX ~/ hoursBlockWidth;

    // actual hour tapped
    final whichHourTapped = widget._hourOffset + whichBlockTapped; // actual hour
    // shift to closest selectable hour
    final whichHourTappedShifted = whichHourTapped % 3 < 1.5 ? (whichHourTapped ~/ 3) * 3 : (whichHourTapped ~/ 3 + 1) * 3;
    if (whichHourTapped <= 48) widget.changeSelectedData(['hourly', whichHourTappedShifted]);
  }

  Widget chartSelectorButton(int index, Widget icon, MaterialColor activeColor) {
    return ButtonTheme(
      minWidth: 20.0,
      height: 20.0,
      child: IconButton(
        onPressed: () => setChartState(index),
        icon: icon,
        color: index == _chartState ? activeColor : Colors.grey[300],
        iconSize: 20.0,
      ),
    );
  }
  Widget chartSelector() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          chartSelectorButton(0, Icon(FontAwesomeIcons.thermometerThreeQuarters), Colors.orange),
          chartSelectorButton(1, Icon(FontAwesomeIcons.tint), Colors.blue),
          chartSelectorButton(2, Icon(FontAwesomeIcons.wind), Colors.green),
        ],
      ),
    );
  }

  Widget chartGenerator(double chartWidth, double chartHeight, double hourWidth, Widget wrappedChart, int valueKey) {
    return Container(
        width: chartWidth,
        height: chartHeight,
        constraints: BoxConstraints(maxWidth: chartWidth - 1.0),
        key: ValueKey(valueKey), // animatedSwitcher required
        child: Stack( // AnimatedPositioned needs to be in stack
          children: <Widget>[
            AnimatedPositioned(
              left: -hourWidth * widget._hourOffset,
              child: Container(
                child: wrappedChart,
                width: chartWidth,
                height: chartHeight,
              ),
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            )
          ],
        )
    );
  }
  Widget temperatureChart() {
    return CustomPaint(
      painter: TemperaturePainter(widget.hourlyDataList, widget.selectedDataPath),
    );
  }
  Widget precipitationChart() {
    return CustomPaint(
      painter: PrecipitationPainter(widget.hourlyDataList, widget.selectedDataPath),
    );
  }
  Widget windChart() {
    return CustomPaint(
      painter: WindPainter(widget.hourlyDataList, widget._isCelsius, widget.selectedDataPath),
    );
  }

  Widget chartWithGestureDetector(double chartWidth, double chartHeight, double hourWidth, double padding) {
    Widget gestureDetector = GestureDetector(
      onTapDown: (details) => canvasTapHandler(details, padding),
      child: Container(
        width: chartWidth,
        height: chartHeight,
        child: Text(' '),
      ),
    );
    Widget chart = AnimatedSwitcher(
      //
      child:
      _chartState == 0 ? chartGenerator(chartWidth, chartHeight, hourWidth, temperatureChart(), 0) :
      _chartState == 1 ? chartGenerator(chartWidth, chartHeight, hourWidth, precipitationChart(), 1) :
      chartGenerator(chartWidth, chartHeight, hourWidth, windChart(), 2),
      //
      duration: Duration(milliseconds: 300),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
    );

    return Stack(
      children: <Widget>[chart, gestureDetector],
    );
  }


  @override
  Widget build(BuildContext context) {
    double horizontalPadding = 10.0;
    double canvasWidth = MediaQuery.of(context).size.width - 2 * horizontalPadding;
    double canvasHeight = 130.0;
    double hourWidth = canvasWidth / 24;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          chartWithGestureDetector(canvasWidth, canvasHeight, hourWidth, horizontalPadding),
          chartSelector(),
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
      minWidth: 80.0,
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: Scrollbar(
        child: Container(
          height: 130.0,
          child: ListView.builder(
            itemCount: dailyDataList.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return dayGraphWidget(dailyDataList[index], index);
            },
          ),
        ),
      ),
    );
  }
}