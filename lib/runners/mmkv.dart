import 'package:hive_benchmark/runners/runner.dart';
import 'package:mmkv/mmkv.dart';

class MMKVRunner implements BenchmarkRunner {
  late MMKV mmkv;

  @override
  String get name => 'MMKV ${MMKV.version}';

  @override
  Future<void> setUp() async {
    await MMKV.initialize();
    mmkv = MMKV.defaultMMKV();
  }

  @override
  Future<void> tearDown() async {
    mmkv.clearMemoryCache();
    mmkv.clearAll();
  }

  @override
  Future<int> batchDeleteInt(List<String> keys) async {
    var s = Stopwatch()..start();
    mmkv.removeValues(keys);
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchDeleteString(List<String> keys) async {
    var s = Stopwatch()..start();
    mmkv.removeValues(keys);
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadInt(List<String> keys) async {
    var s = Stopwatch()..start();
    for (final key in keys) {
      mmkv.decodeInt32(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchReadString(List<String> keys) async {
    var s = Stopwatch()..start();
    for (final key in keys) {
      mmkv.decodeString(key);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteInt(Map<String, int> entries) async {
    final s = Stopwatch()..start();
    for (final key in entries.keys) {
      mmkv.encodeInt32(key, entries[key]!);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }

  @override
  Future<int> batchWriteString(Map<String, String> entries) async {
    final s = Stopwatch()..start();
    for (final key in entries.keys) {
      mmkv.encodeString(key, entries[key]!);
    }
    s.stop();
    return s.elapsedMilliseconds;
  }
}
