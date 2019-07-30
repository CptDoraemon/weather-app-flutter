import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import './weather-data.dart';
import 'dart:math' as math;

export 'hourly-chart-canvas.dart';

// TODO: Abstract common methods

class MyChartDrawingTools {
  void drawPlaceholderText(Canvas canvas, Size size, List<WeatherDataObject> hourlyDataList, double hourlyWidth) {
    final int firstDataHour = DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour == 0 ? 24 : DateTime.fromMillisecondsSinceEpoch(hourlyDataList[0].time).hour;
    final double startXFotPlaceholders = (24 - firstDataHour) * hourlyWidth + 24.0 * hourlyWidth * 2; /* first 48 hours plus the rest of the last natural day */

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

  void drawLegends(Canvas canvas, String topLegendText, String bottomLegendText, double safeWidth, Offset topLegendPosition, Offset bottomLegendPosition, List<dynamic> selectedDataPath, int index) {
    final bool isSelected = (selectedDataPath[0] == 'hourly' && selectedDataPath[1] == index);
    // top data text,
    final TextStyle topDataTextStyle = TextStyle(
        color: isSelected ? Colors.black : Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 8.0
    );
    final TextPainter topTextPainter = TextPainter(
        text: TextSpan(text: topLegendText,
            style: topDataTextStyle),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr
    )
      ..layout(maxWidth: safeWidth);
    topTextPainter.paint(canvas, topLegendPosition);
    // bottom time text
    final TextStyle timeTextStyle = TextStyle(
        color: isSelected ? Colors.black : Colors.grey,
        fontSize: 8.0
    );
    final TextPainter bottomTextPainter = TextPainter(
        text: TextSpan(text: bottomLegendText, style: timeTextStyle),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr
    )
      ..layout(maxWidth: safeWidth);
    bottomTextPainter.paint(canvas, bottomLegendPosition);
  }
}

class TemperaturePainter extends CustomPainter with MyChartDrawingTools{
  final List<WeatherDataObject> hourlyDataList;
  final List<dynamic> selectedDataPath;
  int max = -999;
  int min = 999;
  int range;

  TemperaturePainter(this.hourlyDataList, this.selectedDataPath) {
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
    final double drawableHeight = size.height - topReservedHeight -
        bottomReservedHeight;
    //
    final Paint linePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.0;
    final Paint rectPaint = Paint()
      ..color = Colors.orange[200];
    final Paint rectPaintSelected = Paint()
      ..color = Colors.orange[500];
    final double hourlyWidth = size.width / 24;

    for (int i = 0; i < hourlyDataList.length; i++) {
      bool isSelected = (selectedDataPath[0] == 'hourly' && i - selectedDataPath[1] < 3 && i - selectedDataPath[1] >= 0);
      bool isLast = i == hourlyDataList.length - 1;
      double thisY = getOffsetY(
          bottomReservedHeight, drawableHeight, range, min,
          hourlyDataList[i].temperature);
      double nextY = isLast ? thisY : getOffsetY(
          bottomReservedHeight, drawableHeight, range, min,
          hourlyDataList[i + 1].temperature);
      double thisX = i * hourlyWidth;
      double nextX = (i + 1) * hourlyWidth;
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
      isSelected ? canvas.drawPath(path, rectPaintSelected) : canvas.drawPath(path, rectPaint);
      // text drawing on every third hour
      if (i % 3 == 0) {
        drawLegends(
          canvas,
          hourlyDataList[i].temperature.toString(),
          hourlyDataList[i].timeString,
          3 * hourlyWidth,
          Offset(thisX, thisY - topReservedHeight),
          Offset(thisX, topReservedHeight + drawableHeight + 0.2 * bottomReservedHeight),
          selectedDataPath,
          i
        );
      }
    }

    // placeholder text
    drawPlaceholderText(canvas, size, hourlyDataList, hourlyWidth);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}




class PrecipitationPainter extends CustomPainter with MyChartDrawingTools{
  final List<WeatherDataObject> hourlyDataList;
  final List<dynamic> selectedDataPath;
  int max = 100;
  int min = 0;
  int range = 100;

  PrecipitationPainter(this.hourlyDataList, this.selectedDataPath);

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
      ..color = Colors.blue[200];
    final Paint rectSelectedPaint = Paint()
      ..color = Colors.blue[500];
    final double hourlyWidth = size.width / 24;

    for (int i=0; i<hourlyDataList.length; i++) {
      bool isSelected = (selectedDataPath[0] == 'hourly' && i - selectedDataPath[1] < 3 && i - selectedDataPath[1] >= 0);
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
      isSelected ? canvas.drawPath(path, rectSelectedPaint) : canvas.drawPath(path, rectPaint);
      // text drawing on every third hour
      if (i % 3 == 0) {
        drawLegends(
            canvas,
            '${hourlyDataList[i].precipitation.toString()}%',
            hourlyDataList[i].timeString,
            3 * hourlyWidth,
            Offset(thisX, thisY - topReservedHeight),
            Offset(thisX,
                topReservedHeight + drawableHeight + 0.2 * bottomReservedHeight),
            selectedDataPath,
            i
        );
      }
    }

    // placeholder text
    drawPlaceholderText(canvas, size, hourlyDataList, hourlyWidth);
  }


  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}





class WindPainter extends CustomPainter with MyChartDrawingTools{
  final List<WeatherDataObject> hourlyDataList;
  final bool _isCelsius;
  final List<dynamic> selectedDataPath;
  int max = -999;
  int min = 999;
  int range;

  WindPainter(this.hourlyDataList, this._isCelsius, this.selectedDataPath) {
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

    for (int i=0; i<hourlyDataList.length; i+=3) {
      bool isSelected = (selectedDataPath[0] == 'hourly' && i - selectedDataPath[1] < 3 && i - selectedDataPath[1] >= 0);
      // draw wind on every third hour
      double thisX = i * hourlyWidth;
      double thisY = 0.5 * size.height;
      // legends
      drawLegends(
          canvas,
          '${hourlyDataList[i].windSpeed.toString()} ${_isCelsius ? 'km/h' : 'mph'}',
          hourlyDataList[i].timeString,
          3 * hourlyWidth,
          Offset(thisX, topReservedHeight),
          Offset(thisX, topReservedHeight + drawableHeight + 0.2 * bottomReservedHeight),
          selectedDataPath,
          i
      );
      // direction icon
      canvas.save();
      // text is drawn from top left, but rotation origin has to be the center of the text
      final double iconSize = 10 + 20 * ((hourlyDataList[i].windSpeed - min) / range);
      final double textCenterOffsetX = 0.5 * 0.5 * iconSize; // text A height : width = 2 : 1
      final double textCenterOffsetY = 0.5 * iconSize;
      final double textOriginX = thisX;
      final double textOriginY = topReservedHeight + 0.5 * drawableHeight;
      final double rotationOriginX = textOriginX + textCenterOffsetX;
      final double rotationOriginY = textOriginY + textCenterOffsetY;
      canvas.translate(rotationOriginX, rotationOriginY);
      canvas.rotate(hourlyDataList[i].windBearing / 180 * math.pi);
      canvas.translate(-textCenterOffsetX, -textCenterOffsetY);
      //
      final TextStyle directionStyle = TextStyle(
        color: Colors.green[400],
        fontSize: iconSize,
      );
      final TextStyle directionSelectedStyle = TextStyle(
        color: Colors.green,
        fontSize: iconSize,
        fontWeight: FontWeight.bold
      );
      final TextPainter directionPainter = TextPainter(
        text: TextSpan(text: 'A', style: isSelected ? directionSelectedStyle : directionStyle),
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr,
      )
        ..layout(maxWidth: 3.0 * hourlyWidth);
      directionPainter.paint(canvas, Offset(0, 0));
      canvas.restore();
    }

    // placeholder text
    drawPlaceholderText(canvas, size, hourlyDataList, hourlyWidth);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}