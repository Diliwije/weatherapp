import 'package:flutter/material.dart';

class Constants {
  final primaryColor=Color.fromARGB(255, 134, 107, 252);
  final secondaryColor=const Color( 0xFFBDBDBD);
  final ternaryColor=const Color.fromARGB(255, 16, 51, 155);

  final blackColor=const Color(0xFF000000);
  final greyCokor=const Color(0xFFBDBDBD);

  final linearGradientBlue=const LinearGradient(
 
    begin: Alignment.topRight,
    end: Alignment.topLeft,
    colors:<Color>[Color.fromARGB(255, 134, 107, 252),
    Color.fromARGB(255, 16, 51, 155)],
    stops: [0.0, 1.0],
  );


  final linearGradientPurple=const LinearGradient(
 
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors:<Color>[Color.fromARGB(255, 148, 9, 207),
    Color.fromARGB(255, 64, 1, 90)],
    stops: [0.0, 1.0],
  );
  }