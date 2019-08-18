import 'dart:io';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:hive_benchmark/sqlite_store.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:random_string/random_string.dart' as randStr;
import 'package:shared_preferences/shared_preferences.dart';

const String TABLE_NAME_STR = "kv_str";
const String TABLE_NAME_INT = "kv_int";

class Result {
  int intTime;
  int stringTime;
}

Map<String, int> generateIntEntries(int count) {
  var map = Map<String, int>();
  var random = Random();
  for (var i = 0; i < count; i++) {
    var key = randStr.randomAlphaNumeric(randStr.randomBetween(5, 200));
    var val = random.nextInt(2 ^ 50);
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

Future prepareHive() async {
  var dir = await getApplicationDocumentsDirectory();
  var homePath = path.join(dir.path, 'hive');
  if (await Directory(homePath).exists()) {
    await Directory(homePath).delete(recursive: true);
  }
  await Directory(homePath).create();
  Hive.init(homePath);
}

Future<SqfliteStore> getSqliteStore() async {
  var store = SqfliteStore();
  await store.init();
  return store;
}

Future prepareSharedPrefs() async {
  var prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

Future<int> hiveBatchRead(List<String> keys, bool lazy) async {
  var box = await Hive.openBox('box', lazy: lazy);
  var s = Stopwatch()..start();
  for (var key in keys) {
    box.get(key);
  }
  s.stop();
  await box.close();
  return s.elapsedMilliseconds;
}

Future<int> sqliteBatchReadInt(SqfliteStore store, List<String> keys) async {
  var s = Stopwatch()..start();
  for (var key in keys) {
    await store.getInt(key);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sqliteBatchReadString(SqfliteStore store, List<String> keys) async {
  var s = Stopwatch()..start();
  for (var key in keys) {
    await store.getString(key);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sharedPrefsBatchReadInt(List<String> keys) async {
  var prefs = await SharedPreferences.getInstance();
  var s = Stopwatch()..start();
  for (var key in keys) {
    prefs.getInt(key);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sharedPrefsReadString(List<String> keys) async {
  var prefs = await SharedPreferences.getInstance();
  var s = Stopwatch()..start();
  for (var key in keys) {
    prefs.getString(key);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<List<Result>> benchmarkRead(int count) async {
  var results = [Result(), Result(), Result(), Result()];
  await prepareHive();
  var store = await getSqliteStore();
  await prepareSharedPrefs();

  var intEntries = generateIntEntries(count);
  var intKeys = intEntries.keys.toList()..shuffle();
  await hiveBatchWrite(intEntries);
  await sqliteBatchWriteInt(store, intEntries);
  await sharedPrefsBatchWriteInt(intEntries);
  results[0].intTime = await hiveBatchRead(intKeys, false);
  results[1].intTime = await hiveBatchRead(intKeys, true);
  results[2].intTime = await sqliteBatchReadInt(store, intKeys);
  results[3].intTime = await sharedPrefsBatchReadInt(intKeys);

  await prepareHive();
  await prepareSharedPrefs();

  var stringEntries = generateStringEntries(count);
  var stringKeys = stringEntries.keys.toList()..shuffle();
  await hiveBatchWrite(stringEntries);
  await sqliteBatchWriteString(store, stringEntries);
  await sharedPrefsBatchWriteString(stringEntries);
  results[0].stringTime = await hiveBatchRead(stringKeys, false);
  results[1].stringTime = await hiveBatchRead(stringKeys, true);
  results[2].stringTime = await sqliteBatchReadString(store, stringKeys);
  results[3].stringTime = await sharedPrefsReadString(stringKeys);

  await Hive.close();
  await store.close();

  return results;
}

Future<int> hiveBatchWrite(Map<String, dynamic> entries) async {
  var box = await Hive.openBox('box', lazy: true);
  var s = Stopwatch()..start();
  for (var key in entries.keys) {
    await box.put(key, entries[key]);
  }
  s.stop();
  await box.close();
  return s.elapsedMilliseconds;
}

Future<int> sqliteBatchWriteInt(
    SqfliteStore store, Map<String, int> entries) async {
  var s = Stopwatch()..start();
  for (var key in entries.keys) {
    await store.putInt(key, entries[key]);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sqliteBatchWriteString(
    SqfliteStore store, Map<String, String> entries) async {
  var s = Stopwatch()..start();
  for (var key in entries.keys) {
    await store.putString(key, entries[key]);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sharedPrefsBatchWriteInt(Map<String, int> entries) async {
  var s = Stopwatch()..start();
  var prefs = await SharedPreferences.getInstance();
  for (var key in entries.keys) {
    await prefs.setInt(key, entries[key]);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sharedPrefsBatchWriteString(Map<String, String> entries) async {
  var s = Stopwatch()..start();
  var prefs = await SharedPreferences.getInstance();
  for (var key in entries.keys) {
    await prefs.setString(key, entries[key]);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<List<Result>> benchmarkWrite(int count) async {
  var results = [Result(), Result(), Result()];
  await prepareHive();
  var store = await getSqliteStore();
  await prepareSharedPrefs();

  var intEntries = generateIntEntries(count);
  results[0].intTime = await hiveBatchWrite(intEntries);
  results[1].intTime = await sqliteBatchWriteInt(store, intEntries);
  results[2].intTime = await sharedPrefsBatchWriteInt(intEntries);

  await prepareHive();
  await prepareSharedPrefs();

  var stringEntries = generateStringEntries(count);
  results[0].stringTime = await hiveBatchWrite(stringEntries);
  results[1].stringTime = await sqliteBatchWriteString(store, stringEntries);
  results[2].stringTime = await sharedPrefsBatchWriteString(stringEntries);

  await Hive.close();
  await store.close();

  return results;
}

Future<int> hiveBatchDelete(List<String> keys) async {
  var box = await Hive.openBox('box', lazy: true);
  var s = Stopwatch()..start();
  for (var key in keys) {
    await box.delete(key);
  }
  s.stop();
  await box.close();
  return s.elapsedMilliseconds;
}

Future<int> sqliteBatchDeleteInt(SqfliteStore store, List<String> keys) async {
  var s = Stopwatch()..start();
  for (var key in keys) {
    await store.deleteInt(key);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sqliteBatchDeleteString(
    SqfliteStore store, List<String> keys) async {
  var s = Stopwatch()..start();
  for (var key in keys) {
    await store.deleteString(key);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<int> sharedPrefsBatchDelete(List<String> keys) async {
  var s = Stopwatch()..start();
  var prefs = await SharedPreferences.getInstance();
  for (var key in keys) {
    await prefs.remove(key);
  }
  s.stop();
  return s.elapsedMilliseconds;
}

Future<List<Result>> benchmarkDelete(int count) async {
  var results = [Result(), Result(), Result()];
  await prepareHive();
  var store = await getSqliteStore();
  await prepareSharedPrefs();

  var intEntries = generateIntEntries(count);
  var intKeys = intEntries.keys.toList()..shuffle();
  await hiveBatchWrite(intEntries);
  await sqliteBatchWriteInt(store, intEntries);
  await sharedPrefsBatchWriteInt(intEntries);
  results[0].intTime = await hiveBatchDelete(intKeys);
  results[1].intTime = await sqliteBatchDeleteInt(store, intKeys);
  results[2].intTime = await sharedPrefsBatchDelete(intKeys);

  await prepareHive();
  await prepareSharedPrefs();

  var stringEntries = generateStringEntries(count);
  var stringKeys = stringEntries.keys.toList()..shuffle();
  await hiveBatchWrite(stringEntries);
  await sqliteBatchWriteString(store, stringEntries);
  await sharedPrefsBatchWriteString(stringEntries);
  results[0].stringTime = await hiveBatchDelete(stringKeys);
  results[1].stringTime = await sqliteBatchDeleteString(store, stringKeys);
  results[2].stringTime = await sharedPrefsBatchDelete(stringKeys);

  await Hive.close();
  await store.close();

  return results;
}
