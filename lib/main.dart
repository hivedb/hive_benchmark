import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_benchmark/benchmark.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();

    controller = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    "Hive Benchmark",
                    style: TextStyle(fontSize: 40),
                  ),
                ),
                SizedBox(height: 15),
                TabBar(
                  tabs: <Widget>[
                    Tab(text: "read"),
                    Tab(text: "write"),
                    Tab(text: "delete"),
                  ],
                  labelColor: const Color(0xff7589a2),
                  controller: controller,
                  onTap: (index) {
                    setState(() {});
                  },
                ),
                SizedBox(height: 25),
                Expanded(
                  child:
                      BenchmarkWidget(BenchmarkType.values[controller.index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum BenchmarkType { read, write, delete }

class BenchmarkWidget extends StatefulWidget {
  final BenchmarkType type;

  BenchmarkWidget(this.type);

  @override
  _BenchmarkWidgetState createState() => _BenchmarkWidgetState();
}

class _BenchmarkWidgetState extends State<BenchmarkWidget> {
  bool isPrecise = false;
  static const entrySteps = [10, 20, 50, 100, 200, 500, 1000];

  var entryValue = 0.0;
  int get entries => entrySteps[entryValue.round()];

  var benchmarkRunning = false;
  List<Result>? benchmarkResults;

  @override
  void didChangeDependencies() {
    benchmarkResults = null;
    benchmarkRunning = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (benchmarkResults == null)
          Expanded(
            child: Center(
              child: Text('Run benchmark to show data'),
            ),
          )
        else
          Expanded(
            child: Center(
              child: BenchmarkResult(benchmarkResults!, isPrecise),
            ),
          ),
        SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                value: entryValue,
                min: 0,
                max: (entrySteps.length - 1).toDouble(),
                divisions: entrySteps.length - 2,
                onChanged: (newValue) {
                  setState(() {
                    entryValue = newValue;
                  });
                },
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(entries.toString() + " Entries"),
            ),
          ],
        ),
        if (benchmarkRunning)
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _performBenchmark,
                  child: Text("Benchmark"),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('Precise'),
                  value: isPrecise,
                  onChanged: (bool? value) {
                    isPrecise = !isPrecise;
                    setState(() {});
                  },
                ),
              )
            ],
          ),
        SizedBox(height: 20),
      ],
    );
  }

  _performBenchmark() async {
    var entries = this.entries;
    setState(() {
      benchmarkRunning = true;
    });

    List<Result> results;
    switch (widget.type) {
      case BenchmarkType.read:
        results = await benchmarkRead(entries);
        break;
      case BenchmarkType.write:
        results = await benchmarkWrite(entries);
        break;
      case BenchmarkType.delete:
        results = await benchmarkDelete(entries);
        break;
    }

    setState(() {
      benchmarkRunning = false;
      benchmarkResults = results;
    });
  }
}

class BenchmarkResult extends StatelessWidget {
  final Color leftBarColor = Color(0xff53fdd7);
  final Color rightBarColor = Color(0xffff5182);
  final double width = 12;

  final List<Result> results;
  final bool isPrecise;

  BenchmarkResult(this.results, this.isPrecise);

  List<String> get labels {
    return results.map((r) => r.runner.name).toList();
  }

  int get maxResultTime {
    var max = 0;
    for (var result in results) {
      if (result.intTime > max) {
        max = result.intTime;
      }
      if (result.stringTime > max) {
        max = result.stringTime;
      }
    }
    return max;
  }

  double get preciseTime {
    final List<Result> index = List.from(results);
    index.sort((a, b) => a.intTime.compareTo(b.intTime));
    final preciseIntTime = index[2].intTime;

    index.sort((a, b) => a.stringTime.compareTo(b.stringTime));
    final preciseStringTime = index[2].stringTime;

    return max(max<int>(preciseIntTime, preciseStringTime) + 1, 5) * 1.10;
  }

  List<BarChartGroupData> get barGroups {
    var x = 0;
    return [
      for (final result in results)
        BarChartGroupData(
          barsSpace: 2,
          x: x++,
          barRods: [
            BarChartRodData(
              y: max(result.intTime.toDouble(), 0.1),
              colors: [leftBarColor],
              width: width,
              borderRadius: BorderRadius.circular(6),
            ),
            BarChartRodData(
              y: max(result.stringTime.toDouble(), 0.1),
              colors: [rightBarColor],
              width: width,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 15,
                height: 15,
                child: Container(
                  color: leftBarColor,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Integers',
                style: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 15,
                height: 15,
                child: Container(
                  color: rightBarColor,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Strings',
                style: TextStyle(
                  color: const Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: _buildChart(),
        ),
      ],
    );
  }

  _buildChart() {
    final maxTime = maxResultTime;

    return Container(
      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: BarChart(
            BarChartData(
              maxY: isPrecise ? preciseTime : maxTime.toDouble(),
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTextStyles: (_, value) => TextStyle(
                    color: const Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  margin: 10,
                  reservedSize: 140,
                  rotateAngle: -90,
                  getTitles: (double value) {
                    return labels[value.toInt()];
                  },
                ),
                leftTitles: SideTitles(
                  showTitles: true,
                  getTextStyles: (_, value) => TextStyle(
                    color: const Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  margin: 32,
                  checkToShowTitle: (double minValue,
                      double maxValue,
                      SideTitles sideTitles,
                      double appliedInterval,
                      double value) {
                    var interval = ((maxValue / 10) / appliedInterval).floor() *
                        appliedInterval;
                    if (interval == 0) interval = appliedInterval;
                    return (value % interval == 0);
                  },
                  reservedSize: 65,
                  getTitles: (value) {
                    return '${value.toInt().toString()} ms';
                  },
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }
}
