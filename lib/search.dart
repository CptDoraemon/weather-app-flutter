import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import './spinner.dart';

export 'search.dart';

class SearchCityResults {
  final bool isSuccessful;
  final bool isEmpty;
  final List<SearchCityResultObject> cityList;

  SearchCityResults({this.isSuccessful, this.isEmpty, this.cityList});

  factory SearchCityResults.fromJson(Map<String, dynamic> json) {
    return SearchCityResults(
      isSuccessful: json['status'] == 'success',
      isEmpty: json['rows'].length == 0,
      cityList: json['rows'].length == 0 ? [] : _formatJsonList(json['rows'])
    );
  }

  static List<SearchCityResultObject> _formatJsonList(List<dynamic> jsonList) {
    final List<SearchCityResultObject> list = [];
    print(jsonList);
    for (int i=0; i<jsonList.length; i++) {
      list.add(SearchCityResultObject.fromJson(jsonList[i]));
    }
    return list;
  }
}
class SearchCityResultObject {
  final String city;
  final String province;
  final String country;
  final double longitude;
  final double latitude;

  SearchCityResultObject({this.city, this.province, this.country, this.longitude, this.latitude});

  factory SearchCityResultObject.fromJson(Map<String, dynamic> json) {
    return SearchCityResultObject(
      city: json['city'],
      province: json['province'],
      country: json['country'],
      longitude: json['longitude'] * 1.0,
      latitude: json['latitude'] * 1.0,
    );
  }
}

class SearchTab extends StatefulWidget {
  final Function addNewTab;
  SearchTab(this.addNewTab);

  @override
  State<StatefulWidget> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {

  final _formKey = GlobalKey<FormState>();
  final textFieldController = TextEditingController();
  bool _isTextFieldEmpty = true;
  bool _inputIsLongEnough = false;
  bool _isSendingQuery = false;
  bool _isError = false;
  SearchCityResults _searchResults;
  Timer sendQueryDebounceTimer;

  final double _paddingX = 10.0;
  final EdgeInsets paddingY = const EdgeInsets.symmetric(vertical: 5.0);
  FocusNode _textFieldNode = FocusNode();

  @override
  void initState() {
    super.initState();
    textFieldController.addListener(textChangeHandler);
  }

  @override
  void dispose() {
    super.dispose();
    //
    sendQueryDebounceTimer?.cancel();
    sendQueryDebounceTimer = null;
    // Clean up the controller when the widget is disposed.
    textFieldController.removeListener(textChangeHandler);
    textFieldController.dispose();
    //
    _textFieldNode.dispose();
  }

  void scheduleSendQuery(String queryString) {
    sendQueryDebounceTimer?.cancel();
    sendQueryDebounceTimer = Timer(Duration(milliseconds: 300), () => sendQuery(queryString));
  }

  void sendQuery(String queryString) async {
    setState(() => _isSendingQuery = true);
    String queryStringEncoded = Uri.encodeComponent(queryString);
//    String url = 'http://localhost:5000/api/searchCityName?cityName=$queryStringEncoded';
    String url = 'https://www.xiaoxihome.com/api/searchCityName?cityName=$queryStringEncoded';
    final response = await http.get(url);
    // create new tab => lose focus => textField changed => query already sent => unmounted when response received
    if (!mounted) return;
    setState(() => _isSendingQuery = false);
    if (response.statusCode == 200) {
      setState(() {
        _searchResults = SearchCityResults.fromJson(json.decode(response.body));
      });
    } else {
      setState(() {
        _isError = true;
        _searchResults = null;
      });
    }
  }

  void textChangeHandler() {
    if (textFieldController.text.isEmpty) {
      // empty
      _searchResults = null;
      sendQueryDebounceTimer?.cancel();
      if (!_isTextFieldEmpty) setState(() => _isTextFieldEmpty = true);
    } else if (textFieldController.text.isNotEmpty) {
      if (_isTextFieldEmpty) setState(() => _isTextFieldEmpty = false);
      if (textFieldController.text.length < 3) {
        // length == 1 || length == 2
        _searchResults = null;
        sendQueryDebounceTimer?.cancel();
        if (_inputIsLongEnough) setState(() => _inputIsLongEnough = false);
      } else {
        // length >= 3
        if (!_inputIsLongEnough) setState(() => _inputIsLongEnough = true);
        scheduleSendQuery(textFieldController.text);
      }
    }
  }

  List<Widget> placeholder() {
    return [
      Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
            child: Text('Enter city name', textAlign: TextAlign.center),
          )
      ),
      Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
            child: Text('Only the prominent cities in Canada, United States, and China are supported', textAlign: TextAlign.center),
          )
      ),
    ];
  }

  Widget sendingQueryPlaceholder() {
    return Padding(
      padding: paddingY,
      child: Container(
        height: 20.0,
        child: Center(
          child:
            _isSendingQuery ? Spinner(20.0) : Text(' '),
        ),
      ),
    );
  }

  Widget keepGoingPlaceholder() {
    return Padding(
      padding: paddingY,
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('Keep going'),
          ],
        ),
      ),
    );
  }

  Widget entryWrapper(String text, double longitude, double latitude) {
    return Center(
      child: ButtonTheme(
          minWidth: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: FlatButton(
            onPressed: () {
              widget.addNewTab(longitude, latitude);
            },
            child: Text(text, textAlign: TextAlign.center),
          ),
        )
      );
  }

  Widget plainTextEntryWrapper(String text) {
    return Padding(
      padding: paddingY,
      child: Container(
        height: 20.0,
        child: Text(text),
      ),
    );
  }

  Widget searchField() {
    double usableWidth = MediaQuery.of(context).size.width - 2 * _paddingX;
    double iconWidth = 50.0;
    double textFieldWidth = usableWidth - iconWidth - 15.0;
    final InputBorder border = UnderlineInputBorder(borderSide: BorderSide(width: 2.0, color: Colors.grey[400]));
    return Form(
      key: _formKey,
      child: Container(
        child: Row(
          children: <Widget>[
            Container(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Icon(
                  FontAwesomeIcons.search,
                  color: Colors.grey[400],
                  size: iconWidth - 30.0,
                ),
              )
            ),
            Container(
              width: textFieldWidth,
              child: TextField(
                focusNode: _textFieldNode,
                controller: textFieldController,
                decoration: InputDecoration(enabledBorder: border, focusedBorder: border),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResultList = [];
    if (_searchResults != null) {
      if (!_searchResults.isSuccessful) {
        searchResultList.add(plainTextEntryWrapper('Server is not available'));
      } else if (_searchResults.isEmpty) {
        searchResultList.add(plainTextEntryWrapper('No results found'));
      } else {
        _searchResults.cityList.forEach((i) {
          searchResultList.add(entryWrapper('${i.city}, ${i.province}, ${i.country}.', i.longitude, i.latitude));
        });
      }
    }


    return GestureDetector(
      onTapDown: (details) => _textFieldNode.unfocus(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _paddingX),
        child: ListView(
          children: <Widget>[
            searchField(),
            sendingQueryPlaceholder(),
            if(_isTextFieldEmpty) ...placeholder(),
            if(!_isTextFieldEmpty && !_inputIsLongEnough) keepGoingPlaceholder(),
            if(_isError) plainTextEntryWrapper('Server is not available'),
            if(_inputIsLongEnough) ...searchResultList
          ],
        ),
      ),
    );
  }
}