import 'dart:async';

import 'package:aeroaura/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('forecast requests use the selected coordinates and local timezone', () {
    final uri = WeatherService.buildForecastUri(
      latitude: -33.8688,
      longitude: 151.2093,
    );

    expect(uri.host, 'api.open-meteo.com');
    expect(uri.path, '/v1/forecast');
    expect(uri.queryParameters['latitude'], '-33.8688');
    expect(uri.queryParameters['longitude'], '151.2093');
    expect(uri.queryParameters['timezone'], 'auto');
    expect(uri.queryParameters['daily'], contains('sunrise'));
    expect(uri.queryParameters['hourly'], contains('temperature_2m'));
  });

  test('forecast requests reject coordinates outside geographic bounds', () {
    expect(
      () => WeatherService.buildForecastUri(latitude: 91, longitude: 0),
      throwsArgumentError,
    );
    expect(
      () => WeatherService.buildForecastUri(latitude: 0, longitude: 181),
      throwsArgumentError,
    );
  });

  test('weather service rejects an incomplete coordinate pair', () async {
    await expectLater(
      WeatherService().fetchWeather(latitude: 10),
      throwsArgumentError,
    );
  });

  test('weather service reports unsuccessful API responses', () async {
    final service = WeatherService(
      request: (_) async => http.Response('unavailable', 503),
    );

    await expectLater(
      service.fetchWeather(latitude: 0, longitude: 0),
      throwsA(isA<WeatherServiceException>()),
    );
  });

  test('weather service reports malformed API payloads', () async {
    final service = WeatherService(
      request: (_) async => http.Response('not-json', 200),
    );

    await expectLater(
      service.fetchWeather(latitude: 0, longitude: 0),
      throwsA(isA<WeatherServiceException>()),
    );
  });

  test('weather service reports request timeouts', () async {
    final service = WeatherService(
      request: (_) => Completer<http.Response>().future,
      requestTimeout: const Duration(milliseconds: 1),
    );

    await expectLater(
      service.fetchWeather(latitude: 0, longitude: 0),
      throwsA(isA<WeatherServiceException>()),
    );
  });

}
