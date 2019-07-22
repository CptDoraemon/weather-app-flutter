import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './weather-app.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather by Xiaoxihome',
      home: Tabs(),
      theme: ThemeData(primaryColor: Colors.white),
    );
  }
}
class Tabs extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return TabsState();
  }
}
class TabsState extends State<Tabs> with SingleTickerProviderStateMixin{
  int _tabLength = 3;
  int _currentTabIndex = 1;
  TabController _tabController;

  void setCurrentTabIndex() {
    setState(() => _currentTabIndex = _tabController.index);
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabLength);
    _tabController.addListener(setCurrentTabIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(setCurrentTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  Widget blankAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(10.0),
      child: AppBar(
        toolbarOpacity: 0.0,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: blankAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            WeatherAppLoader(),
            WeatherAppLoader(),
            WeatherAppLoader()
          ]
        ),
        bottomNavigationBar: TabIndicator(_tabLength, _currentTabIndex),
      );
  }
}

class TabIndicator extends StatelessWidget{
  final int _tabLength;
  final int _currentTabIndex;
  TabIndicator(this._tabLength, this._currentTabIndex);

  Widget tabIcon(bool isActive, IconData icon) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 500),
      opacity: isActive ? 1.0 : 0.1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.0),
        child: Icon(
          icon,
          color: Colors.black,
          size: 10.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _tabIcons = [];
    for(int i=0; i<_tabLength; i++) {
      bool isActive = i == _currentTabIndex;
      if (i == 0) {
        _tabIcons.add(tabIcon(isActive, FontAwesomeIcons.search));
      } else if (i == 1) {
        _tabIcons.add(tabIcon(isActive, FontAwesomeIcons.compass));
      } else {
        _tabIcons.add(tabIcon(isActive, FontAwesomeIcons.circle));
      }
    }

    return Container(
      height: 50.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _tabIcons,
      )
    );
  }
}


