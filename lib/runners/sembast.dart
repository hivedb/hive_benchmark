import 'dart:io';

import 'package:hive_benchmark/runners/runner.dart';
import 'package:sembast/sembast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sembast/sembast_io.dart';

class SembasRunner implements BenchmarkRunner {
  late Database db;
  late StoreRef store;

  @override
  String get name => 'Sembast';

  @override
  Future<void> setUp() async {
    var dir = await getApplicationDocumentsDirectory();
    var file = File(path.join(dir.path, 'sembast.db'));
    if (file.existsSync()) {
      await file.delete();
    }

    db = await databaseFactoryIo.openDatabase(file.path);
    store = StoreRef.main();
  }

  @override
  Future<void> tearDown() async {
    await db.close();
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) async {
    var s = Stopwatch()..start();
    await db.transaction((tx) async {
      for (final key in keys) {
        await store.record(key).delete(tx);
      }
    });
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteString(List<String> keys) {
    return batchDeleteInt(keys);
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    var s = Stopwatch()..start();
    await db.transaction((tx) async {
      for (final key in keys) {
        await store.record(key).get(tx);
      }
    });
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadString(List<String> keys) {
    return batchReadInt(keys);
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) async {
    var s = Stopwatch()..start();
    await db.transaction((tx) async {
      for (final key in entries.keys) {
        await store.record(key).put(tx, entries[key]);
      }
    });
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteString(Map<String, String> entries) async {
    var s = Stopwatch()..start();
    await db.transaction((tx) async {
      for (final key in entries.keys) {
        await store.record(key).put(tx, entries[key]);
      }
    });
    s.stop();
    return s.elapsedMilliseconds;
  }
}
