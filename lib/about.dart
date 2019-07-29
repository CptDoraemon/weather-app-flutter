import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

export 'about.dart';

class AboutPage extends StatelessWidget {

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget urlButton(String url, String text) {
    return ButtonTheme(
      minWidth: double.infinity,
      padding: EdgeInsets.all(10.0),
      child: FlatButton(
          onPressed: () => _launchURL(url),
          child: Text(
            text,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          )
      ),
    );
  }

  Widget aboutPageBottomNavigator(BuildContext context) {
    return Container(
      height: 50.0,
      child: Stack(
          children: [
            Positioned(
              left: 20.0,
              top: 0,
              child: IconButton(
                icon: Icon(FontAwesomeIcons.arrowAltCircleLeft),
                onPressed: () => Navigator.pop(context),
                color: Colors.grey,
              )
            ),
          ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          urlButton('https://darksky.net/poweredby/', 'Weather service powered by Dark Sky'),
          urlButton('https://locationiq.com/', 'Location searched by LocationIQ.com'),
          urlButton('https://erikflowers.github.io/weather-icons/', 'Weather Icons'),
          urlButton('https://fontawesome.com/', 'Font Awesome'),
          urlButton('https://www.xiaoxihome.com', 'Made with ❤️ by Xiaoxihome'),
        ],
      ),
      bottomNavigationBar: aboutPageBottomNavigator(context),
//      backgroundColor: Colors.black,
    );
  }
}