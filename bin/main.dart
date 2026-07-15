import 'dart:io';

import 'package:commit_health_gate/src/github.dart';
import 'package:rw_git/rw_git.dart';

Future<void> main() async {
  final env = Platform.environment;

  final token = env['INPUT_GITHUB_TOKEN'] ?? '';
  final lineThresholdStr = env['INPUT_MEGA_COMMIT_LINE_THRESHOLD'] ?? '500';
  final fileThresholdStr = env['INPUT_MEGA_COMMIT_FILE_THRESHOLD'] ?? '20';
  final failOnViolationStr = env['INPUT_FAIL_ON_VIOLATION'] ?? 'false';
  final failOnBurnoutStr = env['INPUT_FAIL_ON_BURNOUT'] ?? 'false';
  final workHoursStartStr = env['INPUT_WORK_HOURS_START'] ?? '9';
  final workHoursEndStr = env['INPUT_WORK_HOURS_END'] ?? '17';
  final workingDirectory = env['INPUT_WORKING_DIRECTORY'] ?? '.';

  final lineThreshold = int.tryParse(lineThresholdStr) ?? 500;
  final fileThreshold = int.tryParse(fileThresholdStr) ?? 20;
  final failOnViolation = failOnViolationStr.toLowerCase() == 'true';
  final failOnBurnout = failOnBurnoutStr.toLowerCase() == 'true';
  final workHoursStart = int.tryParse(workHoursStartStr) ?? 9;
  final workHoursEnd = int.tryParse(workHoursEndStr) ?? 17;

  final eventPath = env['GITHUB_EVENT_PATH'];
  final shas = GitHub.readPrShas(eventPath);

  if (shas == null) {
    stderr.writeln('commit-health-gate: not a pull_request event; '
        'nothing to analyse.');
    return;
  }

  final revisionRange = '${shas.base}..${shas.head}';
  final runner = ProcessRunner.defaultRunner();
  final repositoryPath = Directory(workingDirectory).absolute.path;

  // MEGA COMMITS
  stdout.writeln('Running Mega Commits Check...');
  final megaCommitsHeuristic = MegaCommitsHeuristic(runner);
  final megaCommits = await megaCommitsHeuristic.findMegaCommits(
    repositoryPath,
    lineThreshold: lineThreshold,
    fileThreshold: fileThreshold,
    revisionRange: revisionRange,
  );

  // SUSPICIOUS COMMITS
  stdout.writeln('Running Suspicious Commits Check...');
  final suspiciousCommitsHeuristic = SuspiciousCommitsHeuristic(runner);
  final suspiciousCommits = await suspiciousCommitsHeuristic.findSuspiciousCommits(
    repositoryPath,
    revisionRange: revisionRange,
  );

  // BURNOUT COMMITS
  stdout.writeln('Running Burnout Commits Check...');
  final commitVelocityHeuristic = CommitVelocityHeuristic(runner);
  final burnoutCommits = await commitVelocityHeuristic.findBurnoutCommits(
    repositoryPath,
    revisionRange: revisionRange,
    workHoursStart: workHoursStart,
    workHoursEnd: workHoursEnd,
  );

  final totalMega = megaCommits.length;
  final totalSuspicious = suspiciousCommits.length;
  final totalBurnout = burnoutCommits.length;

  GitHub.writeOutputs({
    'mega-commits-count': '$totalMega',
    'suspicious-commits-count': '$totalSuspicious',
    'burnout-commits-count': '$totalBurnout',
  });

  final sb = StringBuffer();
  sb.writeln('## Commit Health Gate Report');
  
  if (totalMega == 0 && totalSuspicious == 0 && totalBurnout == 0) {
    sb.writeln('✅ All commits look healthy!');
  } else {
    if (totalMega > 0) {
      sb.writeln('### ❌ Mega Commits Found');
      sb.writeln('The following commits exceed the threshold of $lineThreshold lines or $fileThreshold files changed:');
      for (final commit in megaCommits) {
        sb.writeln('- $commit');
      }
      sb.writeln('');
    }
    
    if (totalSuspicious > 0) {
      sb.writeln('### ⚠️ Suspicious Commits Found');
      sb.writeln('The following commits match suspicious patterns:');
      for (final commit in suspiciousCommits) {
        sb.writeln('- $commit');
      }
      sb.writeln('');
    }
    
    if (totalBurnout > 0) {
      sb.writeln('### 🕒 Burnout Commits Found');
      sb.writeln('The following commits were made outside configured working hours ($workHoursStart:00 - $workHoursEnd:00). Please ensure you are taking time to rest!');
      for (final commit in burnoutCommits) {
        sb.writeln('- $commit');
      }
      sb.writeln('');
    }
  }

  final reportMarkdown = sb.toString();
  GitHub.writeStepSummary(reportMarkdown);

  if (token.isNotEmpty) {
    final number = GitHub.prNumber(eventPath);
    final repository = env['GITHUB_REPOSITORY'];
    if (number != null && repository != null) {
      final gh = GitHub(token: token, repository: repository);
      try {
        await gh.upsertStickyComment(number, reportMarkdown);
      } catch (e) {
        stderr.writeln('commit-health-gate: failed to post comment: $e');
      } finally {
        gh.close();
      }
    }
  }

  if ((failOnViolation && (totalMega > 0 || totalSuspicious > 0)) ||
      (failOnBurnout && totalBurnout > 0)) {
    stderr.writeln('commit-health-gate: failing due to violations found.');
    exitCode = 1;
  }
}
