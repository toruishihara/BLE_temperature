import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../model/sqlite_data.dart';

class TemperatureScreen extends StatefulWidget {
  @override
  _TemperatureScreenState createState() => _TemperatureScreenState();
 }

class _TemperatureScreenState extends State<TemperatureScreen> {
  List<FlSpot> _dataSpots = [];
  Timer? _updateTimer;
  int _startUnixTime = 0;
  int _year = 0;
  int _month = 0;
  int _day = 0;
  int _maxDay = 0;
  List<String> monthAbbreviations = [
    '',      // Placeholder for 0-index
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();

    // Initial data fetch
    _fetchTemperatureData();

    // Schedule periodic updates every 20 minute
    _updateTimer = Timer.periodic(Duration(minutes: 20), (timer) {
      _fetchTemperatureData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks
    _updateTimer?.cancel();
    super.dispose();
  }

  Future _fetchTemperatureData() async {
    try {
      _dataSpots = [];
      // Access the database
      final db = await DatabaseHelper.instance.database;

      // Retrieve data
      final results = await db.query('temperature');
      debugPrint('TNI Database Results: $results');

      for (var row in results) {
        String dateStr = row['timestamp'] as String;
        DateTime timeStamp = DateTime.parse(dateStr);

        // Extract Year, Month, Day, and Hour
        if (_year == 0 && _month == 0) {
          _year = timeStamp.year;
          _month = timeStamp.month;
          _day = timeStamp.day;
        }
        if (_maxDay < timeStamp.day) {
          _maxDay = timeStamp.day;
        }

        // Convert to Unix timestamp (seconds since epoch)
        int unixSeconds = timeStamp.millisecondsSinceEpoch ~/ 1000;
        if (_startUnixTime == 0) {
          DateTime dateOnly = DateTime(timeStamp.year, timeStamp.month, timeStamp.day);
          _startUnixTime = dateOnly.millisecondsSinceEpoch ~/ 1000;
        }
        int deltaSec =  unixSeconds - _startUnixTime;

        double tempValue = row['temp_value'] as double;
        //_dataSpots.add(FlSpot(deltaSec.toDouble(), tempValue));
        //print('deltaSec:${deltaSec} temp: ${tempValue}');
        // Update the data
        setState(() {
          _dataSpots.add(FlSpot(deltaSec.toDouble(), tempValue));
        });
      }
    } catch (e) {
      debugPrint('TNI Error: $e');
    } finally {
      debugPrint('diconnect db');
    }
  }

  final Color mainLineColor = Color.fromARGB(255, 0, 0, 0);
  final Color belowLineColor = Color.fromARGB(255, 0, 0, 255);
  final Color aboveLineColor = Color.fromARGB(255, 0, 255, 0);

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    String text;
    int unixTime = value.toInt() + _startUnixTime;
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);

    int hour = dateTime.hour;
    int min = dateTime.minute;

    text = "$hour:00";
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          color: mainLineColor,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color.fromARGB(255, 0, 0, 255),
      fontSize: 12,
    );
    int intValue = value.toInt();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${intValue}', style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Temperature Chart')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            minY: 0.0, // Set minimum Y value
            maxY: 20.0,  // Set maximum Y value
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text(
                  '$_year ${monthAbbreviations[_month]} $_day - $_maxDay',
                  style: TextStyle(
                    fontSize: 10,
                    color: mainLineColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 18,
                  interval: 6*60*60,
                  getTitlesWidget: bottomTitleWidgets,
                ),
              ),
              leftTitles: AxisTitles(
                axisNameSize: 20,
                axisNameWidget: const Text(
                  'Temperature °C',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  reservedSize: 40,
                  getTitlesWidget: leftTitleWidgets,
                ),
              ),
            ),
                  //DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  //return DateFormat('MM/dd').format(date); // Format as MM/DD

            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: _dataSpots,
                isCurved: false,
                barWidth: 0.5, // Thin line
                color: Color.fromARGB(255, 0, 0, 255),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (FlSpot spot, double xPercentage, LineChartBarData bar, int index) {
                    return FlDotCirclePainter(
                      radius: 2.0, // Small dot size
                      color: Color.fromARGB(255, 0, 0, 255), // Dot color matches the line
                    );
                  },
                ),
              ),
            ],
            //lineBarsData: [
            //  LineChartBarData(
            //    spots: _dataSpots,
            //    isCurved: false,
            //    barWidth: 1,
            //    color: Color.fromARGB(255, 0, 0, 255),
            //    dotData: FlDotData(show: true),
            //  ),
            //],
          ),
        ),
      ),
    );
  }
}
