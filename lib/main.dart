import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './weather-app.dart';
import './search.dart';

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
    return TabsState();
  }
}
class TabsState extends State<Tabs> with TickerProviderStateMixin{
  int _currentTabIndex = 1;
  TabController _tabController;
  final List<Map<String, double>> savedTabsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: getTabLength(), initialIndex: 1);
    _tabController.addListener(setCurrentTabIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(setCurrentTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void updateTabController() {
    setState(() {
      _tabController.dispose();
      _tabController = TabController(vsync: this, length: getTabLength(), initialIndex: _currentTabIndex);
      _tabController.addListener(setCurrentTabIndex);
      _tabController.animateTo(getTabLength() - 1, duration: Duration(seconds: 1));
    });
  }

  int getTabLength() {
    return 2 + savedTabsList.length;
  }

  void setCurrentTabIndex() {
    FocusScope.of(context).unfocus();
    setState(() => _currentTabIndex = _tabController.index);
  }

  void addNewTab(double longitude, double latitude) {
    setState(() {
      savedTabsList.add({
        'latitude': latitude,
        'longitude': longitude
      });
      updateTabController();
    });
  }

  List<Widget> buildSavedTabs() {
    final List<Widget> list = [];
    savedTabsList.forEach((map) {
      list.add(WeatherAppLoader(map['longitude'], map['latitude']));
    });
    return list;
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
            SearchTab(addNewTab),
            WeatherAppLoader(null, null),
            if (savedTabsList.length != 0) ...buildSavedTabs(),
          ]
        ),
        bottomNavigationBar: TabIndicator(getTabLength(), _currentTabIndex),
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


