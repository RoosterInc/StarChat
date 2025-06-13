import 'package:flutter/material.dart';
import '../utils/parsing_utils.dart';

class PlanetHousePosition {
  final String date;
  final String dateKey;
  final int year;
  final int month;
  final int day;
  final String ascendantSign;
  final String ascendantSymbol;
  final int ascendantIndex;
  final String rashiId;
  final String planet;
  final String planetSign;
  final String planetSignSymbol;
  final double planetDegrees;
  final double planetLongitude;
  final int houseNumber;
  final String houseName;
  final String houseArea;
  final String houseMeaning;
  final String description;
  final DateTime generatedAt;

  PlanetHousePosition({
    required this.date,
    required this.dateKey,
    required this.year,
    required this.month,
    required this.day,
    required this.ascendantSign,
    required this.ascendantSymbol,
    required this.ascendantIndex,
    required this.rashiId,
    required this.planet,
    required this.planetSign,
    required this.planetSignSymbol,
    required this.planetDegrees,
    required this.planetLongitude,
    required this.houseNumber,
    required this.houseName,
    required this.houseArea,
    required this.houseMeaning,
    required this.description,
    required this.generatedAt,
  });

  factory PlanetHousePosition.fromJson(Map<String, dynamic> json) {
    return PlanetHousePosition(
      date: json['date'] ?? '',
      dateKey: json['date_key'] ?? '',
      year: ParsingUtils.parseInt(json['year']),
      month: ParsingUtils.parseInt(json['month']),
      day: ParsingUtils.parseInt(json['day']),
      ascendantSign: json['ascendant_sign'] ?? '',
      ascendantSymbol: json['ascendant_symbol'] ?? '',
      ascendantIndex: ParsingUtils.parseInt(json['ascendant_index']),
      rashiId: json['rashi_id'] ?? '',
      planet: json['planet'] ?? '',
      planetSign: json['planet_sign'] ?? '',
      planetSignSymbol: json['planet_sign_symbol'] ?? '',
      planetDegrees: ParsingUtils.parseDouble(json['planet_degrees']),
      planetLongitude: ParsingUtils.parseDouble(json['planet_longitude']),
      houseNumber: ParsingUtils.parseInt(json['house_number']),
      houseName: json['house_name'] ?? '',
      houseArea: json['house_area'] ?? '',
      houseMeaning: json['house_meaning'] ?? '',
      description: json['description'] ?? '',
      generatedAt: ParsingUtils.parseDateTime(json['generated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'date_key': dateKey,
      'year': year,
      'month': month,
      'day': day,
      'ascendant_sign': ascendantSign,
      'ascendant_symbol': ascendantSymbol,
      'ascendant_index': ascendantIndex,
      'rashi_id': rashiId,
      'planet': planet,
      'planet_sign': planetSign,
      'planet_sign_symbol': planetSignSymbol,
      'planet_degrees': planetDegrees,
      'planet_longitude': planetLongitude,
      'house_number': houseNumber,
      'house_name': houseName,
      'house_area': houseArea,
      'house_meaning': houseMeaning,
      'description': description,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class PlanetHouseInterpretation {
  final String ascendantSign;
  final String ascendantSymbol;
  final int ascendantIndex;
  final String planet;
  final int houseNumber;
  final String houseName;
  final String houseArea;
  final String overallEffect;
  final int strengthRating;
  final String positiveEffects;
  final String negativeEffects;
  final String careerImpact;
  final String relationshipImpact;
  final String healthImpact;
  final String financialImpact;
  final String spiritualImpact;
  final String remedies;
  final String luckyColors;
  final String luckyNumbers;
  final String luckyDays;
  final String gemstoneRecommendation;
  final String mantraRecommendation;
  final String summary;
  final DateTime generatedAt;

  PlanetHouseInterpretation({
    required this.ascendantSign,
    required this.ascendantSymbol,
    required this.ascendantIndex,
    required this.planet,
    required this.houseNumber,
    required this.houseName,
    required this.houseArea,
    required this.overallEffect,
    required this.strengthRating,
    required this.positiveEffects,
    required this.negativeEffects,
    required this.careerImpact,
    required this.relationshipImpact,
    required this.healthImpact,
    required this.financialImpact,
    required this.spiritualImpact,
    required this.remedies,
    required this.luckyColors,
    required this.luckyNumbers,
    required this.luckyDays,
    required this.gemstoneRecommendation,
    required this.mantraRecommendation,
    required this.summary,
    required this.generatedAt,
  });

  factory PlanetHouseInterpretation.fromJson(Map<String, dynamic> json) {
    return PlanetHouseInterpretation(
      ascendantSign: json['ascendant_sign'] ?? '',
      ascendantSymbol: json['ascendant_symbol'] ?? '',
      ascendantIndex: ParsingUtils.parseInt(json['ascendant_index']),
      planet: json['planet'] ?? '',
      houseNumber: ParsingUtils.parseInt(json['house_number']),
      houseName: json['house_name'] ?? '',
      houseArea: json['house_area'] ?? '',
      overallEffect: json['overall_effect'] ?? '',
      strengthRating: ParsingUtils.parseInt(json['strength_rating']),
      positiveEffects: json['positive_effects'] ?? '',
      negativeEffects: json['negative_effects'] ?? '',
      careerImpact: json['career_impact'] ?? '',
      relationshipImpact: json['relationship_impact'] ?? '',
      healthImpact: json['health_impact'] ?? '',
      financialImpact: json['financial_impact'] ?? '',
      spiritualImpact: json['spiritual_impact'] ?? '',
      remedies: json['remedies'] ?? '',
      luckyColors: json['lucky_colors'] ?? '',
      luckyNumbers: json['lucky_numbers'] ?? '',
      luckyDays: json['lucky_days'] ?? '',
      gemstoneRecommendation: json['gemstone_recommendation'] ?? '',
      mantraRecommendation: json['mantra_recommendation'] ?? '',
      summary: json['summary'] ?? '',
      generatedAt: ParsingUtils.parseDateTime(json['generated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ascendant_sign': ascendantSign,
      'ascendant_symbol': ascendantSymbol,
      'ascendant_index': ascendantIndex,
      'planet': planet,
      'house_number': houseNumber,
      'house_name': houseName,
      'house_area': houseArea,
      'overall_effect': overallEffect,
      'strength_rating': strengthRating,
      'positive_effects': positiveEffects,
      'negative_effects': negativeEffects,
      'career_impact': careerImpact,
      'relationship_impact': relationshipImpact,
      'health_impact': healthImpact,
      'financial_impact': financialImpact,
      'spiritual_impact': spiritualImpact,
      'remedies': remedies,
      'lucky_colors': luckyColors,
      'lucky_numbers': luckyNumbers,
      'lucky_days': luckyDays,
      'gemstone_recommendation': gemstoneRecommendation,
      'mantra_recommendation': mantraRecommendation,
      'summary': summary,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  Color get strengthColor {
    if (strengthRating >= 7) return Colors.green;
    if (strengthRating >= 4) return Colors.orange;
    return Colors.red;
  }

  String get strengthDescription {
    if (strengthRating >= 7) return 'Strong';
    if (strengthRating >= 4) return 'Moderate';
    return 'Weak';
  }
}

class PlanetHouseData {
  final PlanetHousePosition position;
  final PlanetHouseInterpretation? interpretation;

  PlanetHouseData({
    required this.position,
    this.interpretation,
  });

  static const Map<String, String> _planetAssetMap = {
    'sun': 'sun.png',
    'moon': 'Moon.png',
    'mars': 'mars.png',
    'mercury': 'mercury.png',
    'jupiter': 'Jupitor.png',
    'venus': 'Venus.png',
    'saturn': 'Saturn.png',
    'rahu': 'Rahu.png',
    'ketu': 'Ketu.png',
  };

  String get planetImageAsset {
    final planetName = position.planet.toLowerCase();
    final fileName = _planetAssetMap[planetName] ?? '$planetName.png';
    return 'assets/images/planets/$fileName';
  }

  String get housePositionText {
    final number = position.houseNumber;
    if (number == 1) return '1st';
    if (number == 2) return '2nd';
    if (number == 3) return '3rd';
    return '${number}th';
  }

  Color get strengthColor {
    return interpretation?.strengthColor ?? Colors.grey;
  }

  bool get hasInterpretation => interpretation != null;

  int get strengthRating => interpretation?.strengthRating ?? 0;
}

enum VedicPlanet {
  sun('Sun', '☉'),
  moon('Moon', '☽'),
  mars('Mars', '♂'),
  mercury('Mercury', '☿'),
  jupiter('Jupiter', '♃'),
  venus('Venus', '♀'),
  saturn('Saturn', '♄'),
  rahu('Rahu', '☊'),
  ketu('Ketu', '☋');

  const VedicPlanet(this.name, this.symbol);
  final String name;
  final String symbol;

  static List<String> get allPlanetNames =>
      VedicPlanet.values.map((p) => p.name).toList();
}
