import 'package:analyzer/dart/ast/ast.dart';
import 'package:cool_linter/src/rules/ast_analyze_result.dart';

class PreferTrailingCommaResult extends AstAnalyzeResult {
  PreferTrailingCommaResult({
    required AstNode astNode,
  }) : super(astNode: astNode);
}
