import 'dart:math';

import 'package:aeroaura/screens/add_city_page/local_widgets/add_city_page_widget.dart';
import 'package:aeroaura/screens/add_city_page/local_widgets/app_bar.dart';
import 'package:aeroaura/screens/add_city_page/local_widgets/delete_city_dialog.dart';
import 'package:aeroaura/screens/search_city_page/search_city_page.dart';
import 'package:aeroaura/services/weather_service.dart';
import 'package:aeroaura/utils/consts.dart';
import 'package:country_state_city/models/city.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/weather.dart';
import '../../utils/functions.dart';

class AddCityPage extends StatefulWidget {
  final double temp;
  final String wmoCode;
  final String city;
  final double uvIndex;
  const AddCityPage(
      {super.key,
      required this.city,
      required this.temp,
      required this.uvIndex,
      required this.wmoCode});

  @override
  State<AddCityPage> createState() => _AddCityPageState();
}

class _AddCityPageState extends State<AddCityPage> {
  List<String> savedCities = [];
  List<Weather> weathers = [];
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    getSavedCities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      body: SafeArea(
          child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        primary: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 5, top: 15),
        itemCount: 1,
        itemBuilder: (context, index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 10, left: 20, right: 20, bottom: 10),
                child: Material(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Constants.darkTabColor
                      : Constants.lightTabColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.black12,
                          width: 1.5,
                          style: BorderStyle.solid)),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: AddCityPageWidget(
                      city: widget.city,
                      temp: widget.temp,
                      uvIndex: widget.uvIndex,
                      wmoCode: widget.wmoCode),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (loadError != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(loadError!, textAlign: TextAlign.center),
                      TextButton.icon(
                        onPressed: () => getSavedCities(showLoading: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (savedCities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No saved cities yet.'),
                )
              else
                ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  primary: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 5, top: 15),
                  itemCount: savedCities.length,
                  itemBuilder: (context, index) {
                    final weatherData = weathers[index];
                    return Container(
                      padding: const EdgeInsets.only(
                          top: 10, left: 20, right: 20, bottom: 10),
                      child: Material(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Constants.darkTabColor
                            : Constants.lightTabColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white12
                                    : Colors.black12,
                                width: 1.5,
                                style: BorderStyle.solid)),
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        elevation: 5,
                        child: InkWell(
                          onLongPress: () {
                            showDialog(
                                    context: context,
                                    builder: (ctx) => DeleteCityDialog(
                                        city: savedCities[index]))
                                .then((value) =>
                                    getSavedCities(showLoading: true));
                          },
                          splashColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Constants.lightTabColor.withOpacity(0.1)
                                  : Constants.darkTabColor.withOpacity(0.1),
                          child: AddCityPageWidget(
                              city: savedCities[index].split(', ')[0],
                              temp: weatherData.current["temperature_2m"],
                              uvIndex: weatherData.hourly["uv_index"][0],
                              wmoCode: weatherData.current["weather_code"]
                                  .toString()),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(
                height: 70,
              )
            ],
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<dynamic>(
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: true,
            elevation: 10,
            useSafeArea: true,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Constants.darkPrimary
                : Constants.lightPrimary,
            context: context,
            builder: (BuildContext bc) {
              return const SearchCityPage();
            }).then((_) => getSavedCities(showLoading: true)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.lightBlue.shade900
            : Colors.lightBlue.shade50,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.lightBlue.shade50
            : Colors.lightBlue.shade900,
        child: const Icon(CupertinoIcons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> getSavedCities({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cities = prefs.getStringList('saved_cities') ?? <String>[];
      final cityWeathers = await Future.wait(
          cities.map((cityData) => _fetchWeatherForCity(cityData)));
      if (!mounted) return;

      setState(() {
        savedCities = cities;
        weathers = cityWeathers;
        loadError = null;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error is FormatException
            ? 'Saved city coordinates are invalid. Check the saved city data and try again.'
            : 'Could not load saved cities. Check your connection and try again.';
        isLoading = false;
      });
    }
  }

  Future<Weather> _fetchWeatherForCity(String cityData) async {
    final parts = cityData.split(', ');
    if (parts.length != 3) {
      throw const FormatException('Invalid saved city.');
    }
    final latitude = double.tryParse(parts[1]);
    final longitude = double.tryParse(parts[2]);
    if (latitude == null || longitude == null) {
      throw const FormatException('Invalid saved city coordinates.');
    }

    return WeatherService().fetchWeather(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
