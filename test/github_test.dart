import 'dart:convert';
import 'dart:io';

import 'package:commit_health_gate/src/github.dart';
import 'package:test/test.dart';

void main() {
  group('GitHub utilities', () {
    test('prNumber returns null for missing file', () {
      expect(GitHub.prNumber('non_existent_file.json'), isNull);
    });

    test('prNumber reads PR number from payload', () {
      final file = File('test_payload.json')..writeAsStringSync(jsonEncode({
        'pull_request': {'number': 42}
      }));
      expect(GitHub.prNumber(file.path), 42);
      file.deleteSync();
    });

    test('readPrShas returns null for missing file', () {
      expect(GitHub.readPrShas('non_existent_file.json'), isNull);
    });

    test('readPrShas reads SHAs from payload', () {
      final file = File('test_shas.json')..writeAsStringSync(jsonEncode({
        'pull_request': {
          'base': {'sha': 'base_sha'},
          'head': {'sha': 'head_sha'},
        }
      }));
      final shas = GitHub.readPrShas(file.path);
      expect(shas?.base, 'base_sha');
      expect(shas?.head, 'head_sha');
      file.deleteSync();
    });
  });
}
