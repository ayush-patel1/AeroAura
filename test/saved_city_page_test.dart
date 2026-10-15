import 'package:aeroaura/screens/add_city_page/add_city_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('saved cities page handles a missing preference', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: AddCityPage(
          city: 'Current City',
          temp: -273,
          uvIndex: -1,
          wmoCode: '-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved cities yet.'), findsOneWidget);
  });
}