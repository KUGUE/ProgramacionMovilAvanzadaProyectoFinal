import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WeatherApp(),
    );
  }
}

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final LocationService locationService = LocationService();
  final WeatherService weatherService = WeatherService();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  dynamic currentWeatherData;
  List<dynamic> forecastData = [];

  List<WeatherSearch> searchHistory = [];

  late SharedPreferences _prefs;

  DateTime currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
  }

  Future<void> initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    loadSearchHistory();
  }

  void loadSearchHistory() {
    final history = _prefs.getStringList('searchHistory');
    if (history != null) {
      setState(() {
        searchHistory =
            history.map((item) => WeatherSearch.fromJson(item)).toList();
      });
    }
  }

  void saveSearchHistory() {
    final history = searchHistory.map((item) => item.toJson()).toList();
    _prefs.setStringList('searchHistory', history);
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> getCurrentLocationAndWeather() async {
    try {
      final position = await locationService.getCurrentLocation();
      setState(() {
        latitudeController.text = position.latitude.toString();
        longitudeController.text = position.longitude.toString();
        currentDate = DateTime.now();
      });
      await getWeatherData();
    } catch (e) {
      print('Error al obtener la ubicación o el clima actual: $e');
    }
  }

  Future<void> getWeatherData() async {
    try {
      final latitude = double.parse(latitudeController.text);
      final longitude = double.parse(longitudeController.text);
      final currentWeather =
          await weatherService.getCurrentWeather(latitude, longitude);
      final forecast =
          await weatherService.getFiveDayForecast(latitude, longitude);

      final today = DateTime.now();
      final filteredForecast = forecast['list'].where((item) {
        final dateTime = DateTime.parse(item['dt_txt']);
        return dateTime.day != today.day;
      }).toList();

      setState(() {
        currentWeatherData = currentWeather;
        forecastData = filteredForecast;
        searchHistory
            .add(WeatherSearch(latitude, longitude, currentWeather['name']));
      });

      saveSearchHistory();
    } catch (e) {
      print('Error al obtener los datos del clima: $e');
    }
  }

void navigateToAbout() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Acerca de'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Universidad Autonoma de Baja California Sur'),
              Text('Materia: Programacion Movil Avanzada'),
                Text('Turno: Vespertino'),
                     Text('Integrantes del equipo:'),
            Text('Emmanuel Kugue Tapiz'),
            Text('Luis Pablo Escalante Mireles'),
            Text('Manuel Antonio Floriano Miranda'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
  void navigateToHome() {
    setState(() {
      currentWeatherData = null;
      forecastData.clear();
    });

    saveSearchHistory();
  }

  

  void navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherHistoryPage(searchHistory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: navigateToHistory,
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: navigateToAbout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (currentWeatherData == null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Ingresa las coordenadas para obtener el clima actual',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 120.0,
                          child: TextField(
                            controller: latitudeController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Latitud',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120.0,
                          child: TextField(
                            controller: longitudeController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Longitud',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: getWeatherData,
                      child: Text('Obtener clima'),
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: getCurrentLocationAndWeather,
                      child: Text('Usar ubicación actual'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  SizedBox(height: 16.0),
                  Text(
                    'Clima actual en ${currentWeatherData['name']}',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${currentWeatherData['main']['temp'].toStringAsFixed(1)}°',
                        style: TextStyle(fontSize: 48.0),
                      ),
                      SizedBox(width: 16.0),
                      BoxedIcon(
                        getWeatherIcon(currentWeatherData['weather'][0]['id']),
                        size: 64.0,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    currentWeatherData['weather'][0]['main'],
                    style: TextStyle(fontSize: 24.0),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Humedad: ${currentWeatherData['main']['humidity']}%',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Viento: ${currentWeatherData['wind']['speed']} m/s',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(currentDate)}',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Pronóstico para los próximos 5 días',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: forecastData.length,
                    itemBuilder: (context, index) {
                      final forecastItem = forecastData[index];
                      final forecastDateTime = DateTime.parse(forecastItem['dt_txt']);
                      final forecastIcon = forecastItem['weather'][0]['id'];
                      final forecastTemperature = forecastItem['main']['temp'];

                      return ListTile(
                        leading: BoxedIcon(getWeatherIcon(forecastIcon)),
                        title: Text(
                          DateFormat('EEE, dd/MM/yyyy').format(forecastDateTime),
                          style: TextStyle(fontSize: 16.0),
                        ),
                        subtitle: Text(
                          '${forecastTemperature.toStringAsFixed(1)}°',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: navigateToHome,
                    child: Text('Volver'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class WeatherHistoryPage extends StatelessWidget {
  final List<WeatherSearch> searchHistory;

  WeatherHistoryPage(this.searchHistory);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Búsqueda'),
      ),
      body: ListView.builder(
        itemCount: searchHistory.length,
        itemBuilder: (context, index) {
          final item = searchHistory[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('Latitud: ${item.latitude}, Longitud: ${item.longitude}'),
            onTap: () {
              Navigator.pop(context, item);
            },
          );
        },
      ),
    );
  }
}

class WeatherSearch {
  final double latitude;
  final double longitude;
  final String name;

  WeatherSearch(this.latitude, this.longitude, this.name);

  factory WeatherSearch.fromJson(String jsonString) {
    final data = json.decode(jsonString);
    return WeatherSearch(
      data['latitude'],
      data['longitude'],
      data['name'],
    );
  }

  String toJson() {
    return json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
    });
  }
}

class LocationService {
  Future<Position> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }
}

class WeatherService {
  final apiKey = 'e53439a71210ca772364114bf9133974'; // Reemplaza con tu API key de OpenWeatherMap

  Future<Map<String, dynamic>> getCurrentWeather(
      double latitude, double longitude) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getFiveDayForecast(
      double latitude, double longitude) async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    return json.decode(response.body);
  }
}

IconData getWeatherIcon(int condition) {
  if (condition < 300) {
    return WeatherIcons.thunderstorm;
  } else if (condition < 400) {
    return WeatherIcons.showers;
  } else if (condition < 600) {
    return WeatherIcons.rain;
  } else if (condition < 700) {
    return WeatherIcons.snow;
  } else if (condition < 800) {
    return WeatherIcons.fog;
  } else if (condition == 800) {
    return WeatherIcons.day_sunny;
  } else if (condition <= 804) {
    return WeatherIcons.cloudy;
  } else {
    return WeatherIcons.alien;
  }
}


