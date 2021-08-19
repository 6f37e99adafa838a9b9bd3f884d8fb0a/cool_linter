import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:cool_linter/src/config/analysis_settings.dart';
import 'package:cool_linter/src/rules/rule.dart';
import 'package:cool_linter/src/rules/rule_message.dart';
import 'package:pub_semver/pub_semver.dart';

class RegExpRule extends Rule {
  @override
  final RegExp regExpSuppression = RegExp(r'\/\/(\s)?ignore:(\s)?regexp_exclude');

  // late Iterable<RegExp> _patternRegExpList;

  @override
  List<RuleMessage> check({
    required ResolvedUnitResult parseResult,
    required AnalysisSettings analysisSettings,
  }) {
    // _patternRegExpList = analysisSettings.patternRegExpList;

    final String? path = parseResult.path;
    if (path == null) {
      return <RuleMessage>[];
    }

    return _getIncorrectLines(
      parseResult: parseResult,
      // path: path,
      analysisSettings: analysisSettings,
    );
  }

  List<RuleMessage> _getIncorrectLines({
    required ResolvedUnitResult parseResult,
    required AnalysisSettings analysisSettings,
  }) {
    final String? path = parseResult.path;
    if (path == null) {
      return <RuleMessage>[];
    }

    final String content = parseResult.content!;
    final List<ExcludeWord> excludeWordList = analysisSettings.coolLinter?.regexpExclude ?? <ExcludeWord>[];

    if (!analysisSettings.useRegexpExclude) {
      return const <RuleMessage>[];
    }

    final List<RuleMessage> result = <RuleMessage>[];

    try {
      final ParseStringResult parseResult = parseString(
        content: content,
        featureSet: FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: Version.parse('2.12.0'),
          flags: <String>[],
        ),
        throwIfDiagnostics: false,
      );

      final LineInfo lineInfo = parseResult.lineInfo;

      // iterate
      for (final ExcludeWord excludeWord in excludeWordList) {
        int offset;
        int start = 0;

        do {
          if (excludeWord.patternRegExp == null) {
            break;
          }

          offset = content.indexOf(excludeWord.patternRegExp!, start);
          start = offset + 1;

          if (offset != -1) {
            // ignore: always_specify_types
            final offsetLocation = lineInfo.getLocation(offset);

            final RuleMessage ruleMessage = RuleMessage(
              severityName: excludeWord.severity,
              message: 'regexp_exclude: ${excludeWord.hint} for pattern: ${excludeWord.pattern}',
              code: 'regexp_exclude',
              changeMessage: 'cool_linter. need to replace by pattern:',
              location: Location(
                path,
                offset, // offset
                1, // length
                offsetLocation.lineNumber, // startLine
                offsetLocation.columnNumber + 1, // startColumn
                offsetLocation.lineNumber, // endLine
                offsetLocation.columnNumber + 1, // endColumn
              ),
            );

            result.add(ruleMessage);
          }
        } while (offset != -1);
      }

      return result;
    } catch (exc) {
      return const <RuleMessage>[];
    }
  }
}
