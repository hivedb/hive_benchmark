import 'dart:math';

import 'package:hive_benchmark/runners/hive.dart';
import 'package:hive_benchmark/runners/sembast.dart';
import 'package:hive_benchmark/runners/sql_ffi.dart';
import 'package:hive_benchmark/runners/runner.dart';
import 'package:hive_benchmark/runners/shared_preferences.dart';
import 'package:hive_benchmark/runners/sqflite.dart';
import 'package:logging/logging.dart';
import 'package:random_string/random_string.dart' as randStr;

const String TABLE_NAME_STR = "kv_str";
const String TABLE_NAME_INT = "kv_int";

class Result {
  final BenchmarkRunner runner;
  int intTime = 0;
  int stringTime = 0;

  Result(this.runner);
}

final runners = [
  HiveRunner(false),
  HiveRunner(true),
  SqfliteRunner(),
  SharedPreferencesRunner(),
  SqlFfiRunner(),
  SembasRunner(),
];

List<Result> _createResults() {
  return runners.map((r) => Result(r)).toList();
}

Map<String, int> generateIntEntries(int count) {
  var map = Map<String, int>();
  var random = Random();
  for (var i = 0; i < count; i++) {
    var key = randStr.randomAlphaNumeric(randStr.randomBetween(5, 200));
    var val = random.nextInt(1 << 32);
    map[key] = val;
  }
  return map;
}

Map<String, String> generateStringEntries(int count) {
  var map = Map<String, String>();
  for (var i = 0; i < count; i++) {
    var key = randStr.randomAlphaNumeric(randStr.randomBetween(5, 200));
    var val = randStr.randomString(randStr.randomBetween(5, 1000));
    map[key] = val;
  }
  return map;
}

Logger _logger = Logger('Benchmark');

Future<List<Result>> benchmarkRead(int count) async {
  _logger.fine('Benchmarking read($count)');

  var results = _createResults();

  var intEntries = generateIntEntries(count);
  var intKeys = intEntries.keys.toList()..shuffle();

  for (var result in results) {
    _logger.info('Running ${result.runner.name}...');
    await result.runner.setUp();
    await result.runner.batchWriteInt(intEntries);
    result.intTime = await result.runner.batchReadInt(intKeys);
  }

  var stringEntries = generateStringEntries(count);
  var stringKeys = stringEntries.keys.toList()..shuffle();

  for (var result in results) {
    _logger.info('Running ${result.runner.name}...');
    await result.runner.batchWriteString(stringEntries);
    result.stringTime = await result.runner.batchReadString(stringKeys);
  }

  for (var result in results) {
    await result.runner.tearDown();
  }

  return results;
}

Future<List<Result>> benchmarkWrite(int count) async {
  _logger.fine('Benchmarking write($count)');

  final results = _createResults();
  var intEntries = generateIntEntries(count);
  var stringEntries = generateStringEntries(count);

  for (var result in results) {
    _logger.info('Running ${result.runner.name}...');
    await result.runner.setUp();
    result.intTime = await result.runner.batchWriteInt(intEntries);
    result.stringTime = await result.runner.batchWriteString(stringEntries);

    await result.runner.tearDown();
  }

  return results;
}

Future<List<Result>> benchmarkDelete(int count) async {
  _logger.fine('Benchmarking delete($count)');

  final results = _createResults();

  var intEntries = generateIntEntries(count);
  var intKeys = intEntries.keys.toList()..shuffle();
  for (var result in results) {
    _logger.info('Running ${result.runner.name}...');
    await result.runner.setUp();
    await result.runner.batchWriteInt(intEntries);
    result.intTime = await result.runner.batchDeleteInt(intKeys);
  }

  var stringEntries = generateStringEntries(count);
  var stringKeys = stringEntries.keys.toList()..shuffle();
  for (var result in results) {
    _logger.info('Running ${result.runner.name}...');
    await result.runner.batchWriteString(stringEntries);
    result.stringTime = await result.runner.batchDeleteString(stringKeys);
  }

  for (var result in results) {
    await result.runner.tearDown();
  }

  return results;
}
