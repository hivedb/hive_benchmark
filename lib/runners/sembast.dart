import 'package:hive_benchmark/runners/runner.dart';
import 'package:path_provider/path_provider.dart' as paths;
import 'package:path/path.dart' as path;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class SembastRunner implements BenchmarkRunner {
  Database db;
  final strings = StoreRef<String, String>('strings');
  final ints = StoreRef<String, int>('ints');

  @override
  String get name => 'sembast';

  @override
  Future<void> setUp() async {
    final dir = await paths.getApplicationDocumentsDirectory();
    db = await databaseFactoryIo.openDatabase(path.join(dir.path, 'benchmark.db'));
  }

  @override
  Future<void> tearDown() async {
    // nothing to do here, cleared in setUp
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    final s = Stopwatch()..start();
    for (final key in keys) {
      await ints.record(key).get(db);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadString(List<String> keys) async {
    final s = Stopwatch()..start();
    for (final key in keys) {
      await strings.record(key).get(db);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) async {
    final s = Stopwatch()..start();
    for (final key in entries.keys) {
      await ints.record(key).add(db, entries[key]);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteString(Map<String, String> entries) async {
    final s = Stopwatch()..start();
    for (final key in entries.keys) {
      await strings.record(key).add(db, entries[key]);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) async {
    final s = Stopwatch()..start();
    for (final key in keys) {
      await ints.record(key).delete(db);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteString(List<String> keys) async {
    final s = Stopwatch()..start();
    for (final key in keys) {
      await strings.record(key).delete(db);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }
}
