import 'package:analyzer/dart/analysis/results.dart';
import 'package:cool_linter/src/config/analysis_settings.dart';
import 'package:cool_linter/src/rules/always_specify_types_rule/always_specify_types_rule.dart';
import 'package:cool_linter/src/rules/regexp_rule/regexp_rule.dart';
import 'package:cool_linter/src/rules/rule.dart';
import 'package:cool_linter/src/rules/rule_message.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:cool_linter/src/utils/utils.dart';
import 'package:glob/glob.dart';

// TODO: add if exists in analysis options
final List<Rule> kRulesList = <Rule>[
  RegExpRule(),
  AlwaysSpecifyTypesRule(),
];

class Checker {
  const Checker();

  Map<AnalysisError, PrioritizedSourceChange> checkResult({
    required AnalysisSettings analysisSettings,
    required List<Glob> excludesGlobList,
    required ResolvedUnitResult parseResult,
    AnalysisErrorSeverity errorSeverity = AnalysisErrorSeverity.WARNING,
  }) {
    final Map<AnalysisError, PrioritizedSourceChange> result = <AnalysisError, PrioritizedSourceChange>{};

    if (parseResult.content == null || parseResult.path == null) {
      return result;
    }

    final bool isExcluded = AnalysisSettingsUtil.isExcluded(parseResult.path, excludesGlobList);
    if (isExcluded) {
      return result;
    }

    final Iterable<RuleMessage> errorMessageList = kRulesList.map((Rule rule) {
      return rule.check(
        parseResult: parseResult,
        analysisSettings: analysisSettings,
      );
    }).expand((List<RuleMessage> errorMessage) {
      return errorMessage;
    });

    if (errorMessageList.isEmpty) {
      return result;
    }

    // loop through all wrong lines
    errorMessageList.forEach((RuleMessage errorMessage) {
      // fix
      final PrioritizedSourceChange fix = PrioritizedSourceChange(
        1000000,
        SourceChange(
          'Apply fixes for cool_linter.',
          edits: <SourceFileEdit>[
            SourceFileEdit(
              parseResult.path!,
              1, //parseResult.unit?.declaredElement?.source.modificationStamp ?? 1,
              edits: <SourceEdit>[
                SourceEdit(1, 2, errorMessage.changeMessage),
              ],
            )
          ],
        ),
      );

      // error
      final AnalysisError error = AnalysisError(
        AnalysisErrorSeverity(errorMessage.severityName),
        AnalysisErrorType.LINT,
        errorMessage.location,
        errorMessage.message,
        errorMessage.code,
      );

      result[error] = fix;
    });

    return result;
  }
}
