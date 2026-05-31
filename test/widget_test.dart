import 'package:cleanride_app/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows CleanRide login screen', (tester) async {
    await tester.pumpWidget(const CleanRideApp());
    await tester.pumpAndSettle();

    expect(find.text('CleanRide'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
