import 'package:flutter/material.dart';
import 'dart:ui';
import './weather-data.dart';

export 'hourly-chart-canvas.dart';


class PrecipitationPainter extends CustomPainter {
  final List<WeatherDataObject> hourlyDataList;
  int max = -999;
  int min = 999;
  int range;

  PrecipitationPainter(this.hourlyDataList) {
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}