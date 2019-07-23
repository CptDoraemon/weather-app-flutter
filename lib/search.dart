import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

export 'search.dart';

class SearchTab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {

  final _formKey = GlobalKey<FormState>();
  final textFieldController = TextEditingController();
  bool _isTextFieldEmpty = true;
  final double _padding = 10.0;

  @override
  void initState() {
    super.initState();
    textFieldController.addListener(textChangeHandler);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    textFieldController.removeListener(textChangeHandler);
    textFieldController.dispose();
    super.dispose();
  }

  void textChangeHandler() {
    if (textFieldController.text.isEmpty && !_isTextFieldEmpty) {
      setState(() => _isTextFieldEmpty = true);
    } else if (textFieldController.text.isNotEmpty && _isTextFieldEmpty) {
      setState(() => _isTextFieldEmpty = false);
    }
  }

  Widget placeholder() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Container(
        child: Column(
          children: <Widget>[
            Text('Enter city name'),
            Text('Only the cities in Canada, US, and China are supported'),
          ],
        ),
      ),
    );
  }

  Widget entryWrapper(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Container(
        height: 20.0,
        child: Text(text),
      ),
    );
  }

  Widget searchField() {
    double usableWidth = MediaQuery.of(context).size.width - 2 * _padding;
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _padding),
      child: ListView(
        children: <Widget>[
          searchField(),
          _isTextFieldEmpty ? placeholder() : entryWrapper('search result'),
        ],
      ),
    );
  }
}