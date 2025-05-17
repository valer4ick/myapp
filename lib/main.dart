import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' as intl;


void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String? _city;
  WeatherData? _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _city = 'London';
    _fetchWeatherData(_city!);
  }

  Future<void> _fetchWeatherData(String? city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (city == null || city.isEmpty) {
     setState(() {
        _errorMessage = 'Please enter a city';
        _isLoading = false;
      });
      return;
    }

    const apiKey = '53264f0afddb2089613bf30b567a0f0d'; // Replace with your API key
    final apiUrl = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        setState(() {
          _weatherData = WeatherData.fromJson(decodedJson);
          _fetchForecastData(city);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load weather data. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchForecastData(String city) async {
   setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    const apiKey = '99399079086f59b8175f047c1b94b662'; // Replace with your API key
    final apiUrl = 'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
       final List<dynamic> forecastList = decodedJson['list'];
        final List<Forecast> forecasts = forecastList.map((json) => Forecast.fromJson(json)).toList();

        // Filter to get one forecast per day
        final Map<DateTime, Forecast> dailyForecasts = {};
        for (var forecast in forecasts) {
          final date = DateTime(forecast.dateTime.year, forecast.dateTime.month, forecast.dateTime.day);
          if (!dailyForecasts.containsKey(date) || forecast.dateTime.hour > 12) {
            dailyForecasts[date] = forecast;
          }
        }

        setState(() {
          if (_weatherData != null) {
            _weatherData!.forecast = dailyForecasts.values.toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching forecast: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          if (_city != null) {
            await _fetchWeatherData(_city!);
          }
        },
        child: SingleChildScrollView(
         child: Padding(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter city',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _city = value;
                  });
                  if (value.isEmpty) {
                    _fetchWeatherData(_city);
                  }
                },
                onSubmitted: (value) {
                  setState(() {
                    _city = value;
                  });
                  _fetchWeatherData(_city);
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (_weatherData != null)
                WeatherInfo(weatherData: _weatherData!)
              else
                const Text(
                  'Enter a city to see the weather.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class WeatherInfo extends StatelessWidget {
  const WeatherInfo({super.key, required this.weatherData});

  final WeatherData weatherData;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade400, // Set the background color here
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
           weatherData.cityName,
           style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Image.network(
            'http://openweathermap.org/img/wn/${weatherData.iconCode}@2x.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          Text(
            '${weatherData.temperature}°C',
            style: const TextStyle(
               fontSize: 56,
               fontWeight: FontWeight.w300,
               color: Colors.white,
            ),),

          const SizedBox(height: 10),
          Text(
            weatherData.description,
            style: const TextStyle(
              fontSize: 24,
             color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24.0,
            runSpacing: 12.0,
            children: [
              _buildDetail('ощущения', '${weatherData.feelsLike}°C'),
              _buildDetail('Humidity', '${weatherData.humidity}%'),
              _buildDetail('Wind Speed', '${weatherData.windSpeed} m/s'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
           const SizedBox(height: 20),
          if (weatherData.forecast.isEmpty)
            const Text('No forecast available', style: TextStyle(color: Colors.white))
          else
            SizedBox(
              height: 200, // Adjust height as needed
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weatherData.forecast.length,
                itemBuilder: (context, index) {
                  final forecast = weatherData.forecast[index];
                  return Container(
                    width: 120, // Adjust card width as needed
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            intl.DateFormat('E, MMM d')
                                .format(forecast.dateTime),
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 5),
                        Image.network(
                            'http://openweathermap.org/img/wn/${forecast.iconCode}.png',
                            width: 50,
                            height: 50),
                      Text(

                            '${forecast.temperature.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),

      Text(value, style: const TextStyle(color: Colors.white)),
    ],
    );
  }
}

class Forecast {
  final DateTime dateTime;
  final double temperature;
  final String iconCode;
  Forecast({
    required this.dateTime,
    required this.temperature,
    required this.iconCode,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: json['main']['temp'].toDouble(),
      iconCode: json['weather'][0]['icon'],
    );
  }
}

class WeatherData {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconCode;
  final DateTime lastUpdated;
  List<Forecast> forecast = [];

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.lastUpdated,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      lastUpdated: DateTime.now(),
    );
  }
}