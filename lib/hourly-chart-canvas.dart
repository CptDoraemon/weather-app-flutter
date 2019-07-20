import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import './weather-data.dart';

export 'hourly-chart-canvas.dart';


class TemperaturePainter extends CustomPainter {
  final List<WeatherDataObject> hourlyDataList;
  int max = -999;
  int min = 999;
  int range;

  TemperaturePainter(this.hourlyDataList) {
    hourlyDataList.forEach((i) {
      if (i.temperature > max) max = i.temperature;
      if (i.temperature < min) min = i.temperature;
    });
    max = (max*1.1).ceil();
    min = (min/1.1).floor();

    range = max - min;
  }

  double getOffsetY(bottomReservedHeight, drawableHeight, dataRange, dataMin, temperature) {
    return ((1 - (temperature - dataMin) / dataRange)) * drawableHeight + bottomReservedHeight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double topReservedHeight = 0.2 * size.height;
    final double bottomReservedHeight = 0.2 * size.height;
    final double drawableHeight = size.height - topReservedHeight - bottomReservedHeight;
    //
    final Paint linePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.0;
    final Paint rectPaint = Paint()
      ..color = Colors.orange[300];
    final double hourlyWidth = size.width / 24;

    for (int i=0; i<hourlyDataList.length - 1; i++) {
      double thisY = getOffsetY(bottomReservedHeight, drawableHeight, range, min, hourlyDataList[i].temperature);
      double nextY = getOffsetY(bottomReservedHeight, drawableHeight, range, min, hourlyDataList[i + 1].temperature);
      double thisX = i * hourlyWidth;
      double nextX= (i + 1) * hourlyWidth;
      // line
      Offset offsetStart = Offset(thisX, thisY);
      Offset offsetEnd = Offset(nextX, nextY);
      canvas.drawLine(offsetStart, offsetEnd, linePaint);
      // area
      Path path = Path();
      path.moveTo(thisX, topReservedHeight + drawableHeight); //LB
      path.lineTo(thisX, thisY); //LT
      path.lineTo(nextX, nextY); //RT
      path.lineTo(nextX, topReservedHeight + drawableHeight); //RB
      path.close();
      canvas.drawPath(path, rectPaint);
      // text drawing on every third hour
      if (i % 3 == 0) {
        // temperature text,
        final TextStyle temperatureTextStyle = TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12.0
        );
        final TextPainter temperatureTextPainter = TextPainter(
            text: TextSpan(text: hourlyDataList[i].temperature.toString(), style: temperatureTextStyle),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.ltr
        )
          ..layout(maxWidth: 24.0);
        temperatureTextPainter.paint(canvas, Offset(thisX, thisY - topReservedHeight));
        // time text
        final TextStyle timeTextStyle = TextStyle(
            color: Colors.grey,
            fontSize: 8.0
        );
        final TextPainter timeTextPainter = TextPainter(
            text: TextSpan(text: hourlyDataList[i].timeString, style: timeTextStyle),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.ltr
        )
          ..layout(maxWidth: 30.0);
        timeTextPainter.paint(canvas, Offset(thisX, topReservedHeight + drawableHeight + 0.2 * bottomReservedHeight));
      }
    }

    // placeholder text
    final int firstDataHour = DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour == 0 ? 24 : DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour;
    final double startXFotPlaceholders = 24 - firstDataHour + 24.0 * hourlyWidth * 2;

    for (int i=0; i<5; i++) {
      final TextStyle placeholderTextStyle = TextStyle(
        color: Colors.grey,
        fontSize: 8.0,
        fontWeight: FontWeight.bold,
      );
      final TextPainter placeholderTextPainter = TextPainter(
        text: TextSpan(text: 'Hourly forecasts are only available for next 48 hours'.toUpperCase(), style: placeholderTextStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )
        ..layout(maxWidth: 24.0 * hourlyWidth, minWidth: 24.0 * hourlyWidth);
      placeholderTextPainter.paint(canvas, Offset((24.0 * hourlyWidth) * i + startXFotPlaceholders, size.height * 0.5 - 12));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}




class PrecipitationPainter extends CustomPainter {
  final List<WeatherDataObject> hourlyDataList;
  int max = 100;
  int min = 0;
  int range = 100;

  PrecipitationPainter(this.hourlyDataList);

  double getOffsetY(precipitation, drawableHeight, bottomReservedHeight) {
    return ((1 - precipitation / range)) * drawableHeight + bottomReservedHeight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double topReservedHeight = 0.2 * size.height;
    final double bottomReservedHeight = 0.2 * size.height;
    final double drawableHeight = size.height - topReservedHeight - bottomReservedHeight;
    //
    final Paint linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;
    final Paint rectPaint = Paint()
      ..color = Colors.blue[300];
    final double hourlyWidth = size.width / 24;

    for (int i=0; i<hourlyDataList.length - 1; i++) {
      double thisY = getOffsetY(hourlyDataList[i].precipitation , drawableHeight, bottomReservedHeight);
      double nextY = thisY;
      double thisX = i * hourlyWidth;
      double nextX= (i + 1) * hourlyWidth;
      // line
      Offset offsetStart = Offset(thisX, thisY);
      Offset offsetEnd = Offset(nextX, nextY);
      canvas.drawLine(offsetStart, offsetEnd, linePaint);
      // area
      Path path = Path();
      path.moveTo(thisX, topReservedHeight + drawableHeight); //LB
      path.lineTo(thisX, thisY); //LT
      path.lineTo(nextX, nextY); //RT
      path.lineTo(nextX, topReservedHeight + drawableHeight); //RB
      path.close();
      canvas.drawPath(path, rectPaint);
      // text drawing on every third hour
      if (i % 3 == 0) {
        // precipitation text,
        final TextStyle temperatureTextStyle = TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12.0
        );
        final TextPainter temperatureTextPainter = TextPainter(
            text: TextSpan(text: '${hourlyDataList[i].precipitation.toString()}%', style: temperatureTextStyle),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.ltr
        )
          ..layout(maxWidth: 3 * hourlyWidth);
        temperatureTextPainter.paint(canvas, Offset(thisX, thisY - topReservedHeight));
        // time text
        final TextStyle timeTextStyle = TextStyle(
            color: Colors.grey,
            fontSize: 8.0
        );
        final TextPainter timeTextPainter = TextPainter(
            text: TextSpan(text: hourlyDataList[i].timeString, style: timeTextStyle),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.ltr
        )
          ..layout(maxWidth: 30.0);
        timeTextPainter.paint(canvas, Offset(thisX, topReservedHeight + drawableHeight + 0.2 * bottomReservedHeight));
      }
    }

    // placeholder text
    final int firstDataHour = DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour == 0 ? 24 : DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour;
    final double startXFotPlaceholders = 24 - firstDataHour + 24.0 * hourlyWidth * 2;

    for (int i=0; i<5; i++) {
      final TextStyle placeholderTextStyle = TextStyle(
        color: Colors.grey,
        fontSize: 8.0,
        fontWeight: FontWeight.bold,
      );
      final TextPainter placeholderTextPainter = TextPainter(
        text: TextSpan(text: 'Hourly forecasts are only available for next 48 hours'.toUpperCase(), style: placeholderTextStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )
        ..layout(maxWidth: 24.0 * hourlyWidth, minWidth: 24.0 * hourlyWidth);
      placeholderTextPainter.paint(canvas, Offset((24.0 * hourlyWidth) * i + startXFotPlaceholders, size.height * 0.5 - 12));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}





class WindPainter extends CustomPainter {
  final List<WeatherDataObject> hourlyDataList;
  final bool _isCelsius;
  int max = -999;
  int min = 999;
  int range;

  WindPainter(this.hourlyDataList, this._isCelsius) {
    hourlyDataList.forEach((i) {
      if (i.windSpeed > max) max = i.windSpeed;
      if (i.windSpeed < min) min = i.windSpeed;
    });
    max = (max*1.1).ceil();
    min = (min/1.1).floor();

    range = max - min;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double topReservedHeight = 0.2 * size.height;
    final double bottomReservedHeight = 0.2 * size.height;
    final double drawableHeight = size.height - topReservedHeight - bottomReservedHeight;
    //
    final double hourlyWidth = size.width / 24;
    final Paint pathPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0;

    for (int i=0; i<hourlyDataList.length - 1; i+=3) {
      // draw wind on every third hour
      double thisX = i * hourlyWidth;
      double thisY = 0.5 * size.height;
      // direction icon

      // windSpeed text,
      final TextStyle temperatureTextStyle = TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 8.0
      );
      final TextPainter temperatureTextPainter = TextPainter(
          text: TextSpan(text: '${hourlyDataList[i].windSpeed.toString()} ${_isCelsius ? 'km/h' : 'mph'}', style: temperatureTextStyle),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.ltr
      )
        ..layout(maxWidth: 3 * hourlyWidth);
      temperatureTextPainter.paint(canvas, Offset(thisX, topReservedHeight));
      // time text
      final TextStyle timeTextStyle = TextStyle(
          color: Colors.grey,
          fontSize: 8.0
      );
      final TextPainter timeTextPainter = TextPainter(
          text: TextSpan(text: hourlyDataList[i].timeString, style: timeTextStyle),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.ltr
      )
        ..layout(maxWidth: 30.0);
      timeTextPainter.paint(canvas, Offset(thisX, topReservedHeight + drawableHeight + 0.2 * bottomReservedHeight));
    }

    // placeholder text
    final int firstDataHour = DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour == 0 ? 24 : DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour;
    final double startXFotPlaceholders = 24 - firstDataHour + 24.0 * hourlyWidth * 2;

    for (int i=0; i<5; i++) {
      final TextStyle placeholderTextStyle = TextStyle(
        color: Colors.grey,
        fontSize: 8.0,
        fontWeight: FontWeight.bold,
      );
      final TextPainter placeholderTextPainter = TextPainter(
        text: TextSpan(text: 'Hourly forecasts are only available for next 48 hours'.toUpperCase(), style: placeholderTextStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )
        ..layout(maxWidth: 24.0 * hourlyWidth, minWidth: 24.0 * hourlyWidth);
      placeholderTextPainter.paint(canvas, Offset((24.0 * hourlyWidth) * i + startXFotPlaceholders, size.height * 0.5 - 12));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}