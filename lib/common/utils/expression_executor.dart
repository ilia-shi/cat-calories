import 'package:math_expressions/math_expressions.dart';

class ExpressionExecutor {
  static double execute(String expression) {
    try {
      Expression exp = Parser().parse(expression);

      return exp.evaluate(EvaluationType.REAL, ContextModel());
    } catch (e) {
      return 0;
    }
  }
}
