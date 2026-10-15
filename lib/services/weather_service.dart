// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:aeroaura/models/weather.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

typedef WeatherRequest = Future<http.Response> Function(Uri uri);

class WeatherServiceException implements Exception {
  final String message;

  const WeatherServiceException(this.message);

  @override
  String toString() => message;
}

class WeatherService {
  WeatherService({
    WeatherRequest? request,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _request = request ?? http.get;

  final WeatherRequest _request;
  final Duration requestTimeout;

  Future<Weather> fetchWeather({double? latitude, double? longitude}) async {
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('Latitude and longitude must be provided together.');
    }

    if (kDebugMode) {
      print('fetching');
    }
    Position position;
    if (latitude != null && longitude != null) {
      // Use provided latitude and longitude
      position = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 100,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } else {
      // Fallback to current location
      position = await _determinePosition();
    }
    // print(position.latitude);
    // print(position.longitude);
    final Uri uri = buildForecastUri(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    late final http.Response response;
    try {
      response = await _request(uri).timeout(requestTimeout);
    } on TimeoutException {
      throw const WeatherServiceException(
          'Weather request timed out. Please try again.');
    } on http.ClientException {
      throw const WeatherServiceException(
          'Could not connect to the weather service. Check your connection.');
    }

    if (response.statusCode != 200) {
      throw WeatherServiceException(
          'Weather service returned status ${response.statusCode}.');
    }

    try {
      final dynamic json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      return Weather.fromJson(json);
    } on FormatException {
      throw const WeatherServiceException(
          'Weather service returned invalid data. Please try again later.');
    } on TypeError {
      throw const WeatherServiceException(
          'Weather service returned incomplete data. Please try again later.');
    }
  }

  static Uri buildForecastUri({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
          latitude, 'latitude', 'Must be between -90 and 90.');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
          longitude, 'longitude', 'Must be between -180 and 180.');
    }

    return Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,cloud_cover,surface_pressure,wind_speed_10m,wind_direction_10m',
      'hourly':
          'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,precipitation,weather_code,surface_pressure,visibility,wind_speed_10m,wind_direction_10m,uv_index,is_day',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_hours,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant',
      'timezone': 'auto',
      'past_days': '0',
      'forecast_hours': '24',
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }
}
