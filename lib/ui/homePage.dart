import 'package:flutter/material.dart';
import '../widgets/constants.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  final TextEditingController _cityController = TextEditingController();
  final Constants _constants = Constants();

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
      backgroundColor: const Color.fromARGB(255, 225, 227, 230),
      body:Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.only(top: 70, left: 10, right: 10),
        color: _constants.primaryColor.withOpacity(.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              height: size.height * .7,
              decoration: BoxDecoration(
                gradient: _constants.linearGradientBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow:  [
                  BoxShadow(
                    color: _constants.primaryColor.withOpacity(.2),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('name',width: 35,height: 35),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('name',width: 20,height: 20),
                          const SizedBox(width: 5),
                          Text(location,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.white)),
                          IconButton(onPressed:() {} ,icon: const Icon(Icons.keyboard_arrow_down,color: Colors.white,size: 20))
                        ],
                      ),
                       ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/profile.jpg',width: 35,height: 35,fit: BoxFit.cover,),
                  )
                    ]

                  ),
                  SizedBox(
                    height: 150,
                    child: Image.asset('assets/weather.jpg',fit: BoxFit.cover),
                  )
                 
                ],
              ),
            )]
       
      )
    )
    )
    ;
  }
}