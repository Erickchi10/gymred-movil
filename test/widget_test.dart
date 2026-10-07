import 'package:flutter_test/flutter_test.dart';
import 'package:gymred_movil/main.dart';

void main() {
  testWidgets('La app abre', (tester) async {
    await tester.pumpWidget(const GymredApp());
  });
}
