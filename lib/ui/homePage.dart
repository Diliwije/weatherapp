import 'package:flutter/material.dart';
import '../widgets/constants.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  final TextEditingController _cityController = TextEditingController();
  final Constants constants = Constants();

  static String ApiKey = 'c7beefde8d254041acb121923261902';

  String location = 'Colombo';
  String weatherIcon = 'heavyrain.jpg';
  int temperature = 0;
  String weatherDescription = 'Loading...';
  int humidity = 0;
  int windSpeed = 0;
  int cloud=0;
  String currentDate = '';

  List hourlyWeatherforecasts = [];
  List dailyWeatherforecasts = [];

  String searchWeatherAPI='http://api.weatherapi.com/v1/current.json?key=$ApiKey&days=7&q=';

  @override
  Widget build(BuildContext context) {
    
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 55, 106, 225),
      body:Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
      )
    );
  }
}