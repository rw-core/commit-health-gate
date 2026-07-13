import 'dart:convert';
import 'dart:io';

import 'package:commit_health_gate/src/github.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

    test('writeStepSummary writes to target file', () {
      final file = File('test_summary.md');
      if (file.existsSync()) file.deleteSync();
      GitHub.writeStepSummary('Hello World', path: file.path);
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), 'Hello World\n');
      file.deleteSync();
    });

    test('writeOutputs writes to target file', () {
      final file = File('test_output.txt');
      if (file.existsSync()) file.deleteSync();
      GitHub.writeOutputs({'key1': 'value1', 'key2': 'value2'}, path: file.path);
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), 'key1=value1\nkey2=value2\n');
      file.deleteSync();
    });

    test('upsertStickyComment creates a new comment if none exists', () async {
      int postCount = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response('[]', 200);
        } else if (request.method == 'POST') {
          postCount++;
          expect(request.url.path, contains('/issues/42/comments'));
          final body = jsonDecode(request.body);
          expect(body['body'], contains('My comment'));
          expect(body['body'], contains(GitHub.marker));
          return http.Response('{}', 201);
        }
        return http.Response('Not Found', 404);
      });

      final github = GitHub(
        token: 'test_token',
        repository: 'owner/repo',
        client: mockClient,
      );

      await github.upsertStickyComment(42, 'My comment');
      expect(postCount, 1);
    });

    test('upsertStickyComment patches existing comment if it exists', () async {
      int patchCount = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode([
            {
              'id': 123,
              'body': 'Old comment\n\n${GitHub.marker}',
            }
          ]), 200);
        } else if (request.method == 'PATCH') {
          patchCount++;
          expect(request.url.path, contains('/issues/comments/123'));
          final body = jsonDecode(request.body);
          expect(body['body'], contains('Updated comment'));
          expect(body['body'], contains(GitHub.marker));
          return http.Response('{}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final github = GitHub(
        token: 'test_token',
        repository: 'owner/repo',
        client: mockClient,
      );

      await github.upsertStickyComment(42, 'Updated comment');
      expect(patchCount, 1);
    });
  });
}
