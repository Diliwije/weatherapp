import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── Constants ───────────────────────────────────────────────────────────────
class Constants {
  final Color primaryColor = const Color(0xFF1A237E);

  final LinearGradient linearGradientBlue = const LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF0A1F6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Homepage ─────────────────────────────────────────────────────────────────
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController();
  final Constants _constants = Constants();
  final FocusNode _searchFocus = FocusNode();

  // ── FIXED: using HTTPS ──
  static const String _apiKey = 'c7beefde8d254041acb121923261902';
  static const String _baseUrl =
      'https://api.weatherapi.com/v1/forecast.json';

  // ── State ──
  bool _isLoading = false;
  String? _errorMessage;

  String location           = '';
  String country            = '';
  int    temperature        = 0;
  int    feelsLike          = 0;
  String weatherDescription = '';
  String weatherCondition   = '1000';
  int    humidity           = 0;
  int    windSpeed          = 0;
  int    cloud              = 0;
  int    uvIndex            = 0;
  String sunrise            = '--:--';
  String sunset             = '--:--';
  double visibility         = 0;
  String currentDate        = '';
  bool   isDay              = true;

  List<Map<String, dynamic>> hourlyForecasts = [];
  List<Map<String, dynamic>> dailyForecasts  = [];

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fetchWeather('Colombo');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cityController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ─── API Call ─────────────────────────────────────────────────────────────
  Future<void> _fetchWeather(String city) async {
    if (city.trim().isEmpty) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '$_baseUrl?key=$_apiKey&q=${Uri.encodeComponent(city.trim())}&days=7&aqi=no&alerts=no',
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _parseWeatherData(jsonDecode(response.body));
        _fadeController
          ..reset()
          ..forward();
      } else if (response.statusCode == 400) {
        setState(() =>
            _errorMessage = 'City "$city" not found.\nPlease try another city.');
      } else if (response.statusCode == 403) {
        setState(() => _errorMessage = 'API key error. Please check your key.');
      } else {
        setState(() =>
            _errorMessage = 'Server error (${response.statusCode}).\nTry again.');
      }
    } on Exception catch (e) {
      setState(() =>
          _errorMessage = 'Network error.\nCheck your internet connection.\n\n${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Parse API Response ───────────────────────────────────────────────────
  void _parseWeatherData(Map<String, dynamic> data) {
    final current  = data['current']  as Map<String, dynamic>;
    final loc      = data['location'] as Map<String, dynamic>;
    final forecast = data['forecast']['forecastday'] as List;

    // ── Hourly (next hours from now) ──
    final todayHours = forecast[0]['hour'] as List;
    final nowHour    = DateTime.now().hour;
    final upcoming =
        todayHours.where((h) => DateTime.parse(h['time']).hour > nowHour).toList();

    // Pad with tomorrow's hours if less than 5 remain today
    if (upcoming.length < 5 && forecast.length > 1) {
      upcoming.addAll(
          (forecast[1]['hour'] as List).take(5 - upcoming.length));
    }

    final parsedHourly = upcoming.take(5).map<Map<String, dynamic>>((h) => {
          'time': _formatHour(h['time']),
          'icon': _conditionIcon(h['condition']['code'], h['is_day'] == 1),
          'temp': (h['temp_c'] as num).round(),
        }).toList();

    // ── Daily ──
    final parsedDaily =
        forecast.map<Map<String, dynamic>>((d) => {
              'day' : _formatDay(d['date']),
              'icon': _conditionIcon(d['day']['condition']['code'], true),
              'high': (d['day']['maxtemp_c'] as num).round(),
              'low' : (d['day']['mintemp_c'] as num).round(),
            }).toList();

    final astro = forecast[0]['astro'];

    setState(() {
      location            = loc['name'];
      country             = loc['country'];
      temperature         = (current['temp_c'] as num).round();
      feelsLike           = (current['feelslike_c'] as num).round();
      weatherDescription  = current['condition']['text'];
      weatherCondition    = current['condition']['code'].toString();
      humidity            = (current['humidity'] as num).round();
      windSpeed           = (current['wind_kph'] as num).round();
      cloud               = (current['cloud'] as num).round();
      uvIndex             = (current['uv'] as num).round();
      visibility          = (current['vis_km'] as num).toDouble();
      isDay               = current['is_day'] == 1;
      sunrise             = astro['sunrise'];
      sunset              = astro['sunset'];
      currentDate         = _formatDate(loc['localtime']);
      hourlyForecasts     = parsedHourly;
      dailyForecasts      = parsedDaily;
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _formatHour(String t) {
    final dt     = DateTime.parse(t);
    final h      = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h $suffix';
  }

  String _formatDay(String d) {
    final dt   = DateTime.parse(d);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }

  String _formatDate(String localtime) {
    final d      = DateTime.parse(localtime);
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  IconData _conditionIcon(dynamic codeRaw, bool day) {
    final code = int.tryParse(codeRaw.toString()) ?? 1000;
    if (code == 1000) return day ? Icons.wb_sunny        : Icons.nights_stay;
    if (code <= 1003) return day ? Icons.wb_cloudy        : Icons.nights_stay;
    if (code <= 1009) return Icons.cloud;
    if (code <= 1030) return Icons.foggy;
    if (code <= 1087) return Icons.thunderstorm;
    if (code <= 1117) return Icons.ac_unit;
    if (code <= 1147) return Icons.foggy;
    if (code <= 1201) return Icons.grain;
    if (code <= 1225) return Icons.ac_unit;
    if (code <= 1282) return Icons.thunderstorm;
    return Icons.wb_sunny;
  }

  Color _weatherIconColor() {
    final code = int.tryParse(weatherCondition) ?? 1000;
    if (code == 1000) return isDay ? const Color(0xFFFFC107) : const Color(0xFF90CAF9);
    if (code <= 1009) return const Color(0xFFB0BEC5);
    if (code <= 1087) return const Color(0xFF7986CB);
    return const Color(0xFF64B5F6);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar always on top ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: _buildSearchBar(),
            ),
            // ── Content ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1565C0)),
                          SizedBox(height: 16),
                          Text('Fetching weather…',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? _buildError()
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _cityController,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        onSubmitted: (val) {
          _searchFocus.unfocus();
          _fetchWeather(val);
        },
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search any city…',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF1565C0), size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send_rounded,
                color: Color(0xFF1565C0), size: 20),
            onPressed: () {
              _searchFocus.unfocus();
              _fetchWeather(_cityController.text);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () => _fetchWeather(
                _cityController.text.isEmpty
                    ? 'Colombo'
                    : _cityController.text,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        children: [
          _buildMainCard(),
          const SizedBox(height: 16),
          if (hourlyForecasts.isNotEmpty) _buildHourlyCard(),
          const SizedBox(height: 16),
          if (dailyForecasts.isNotEmpty) _buildWeeklyCard(),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Main Weather Card ──────────────────────────────────────────────────────
  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _constants.linearGradientBlue,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _constants.primaryColor.withOpacity(.4),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location + date
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$location, $country',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(currentDate,
              style: TextStyle(
                  color: Colors.white.withOpacity(.6), fontSize: 13)),

          const SizedBox(height: 24),

          // Temperature + weather icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temperature°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.w200,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(weatherDescription,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Feels like $feelsLike°C',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.5),
                            fontSize: 13)),
                  ],
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.1),
                ),
                child: Icon(
                  _conditionIcon(weatherCondition, isDay),
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Quick stats strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickStat(
                    Icons.water_drop_outlined, '$humidity%', 'Humidity'),
                _vDivider(),
                _quickStat(Icons.air, '${windSpeed}km/h', 'Wind'),
                _vDivider(),
                _quickStat(Icons.cloud_outlined, '$cloud%', 'Cloud'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStat(IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(label,
          style:
              TextStyle(color: Colors.white.withOpacity(.55), fontSize: 11)),
    ]);
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(.2));

  // ── Hourly Forecast Card ───────────────────────────────────────────────────
  Widget _buildHourlyCard() {
    return _sectionCard(
      title: 'Next Hours',
      child: SizedBox(
        height: 95,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: hourlyForecasts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f      = hourlyForecasts[i];
            final active = i == 0;
            return Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1565C0)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(f['time'],
                      style: TextStyle(
                          fontSize: 11,
                          color: active
                              ? Colors.white70
                              : Colors.black54)),
                  Icon(f['icon'] as IconData,
                      color: active
                          ? Colors.white
                          : const Color(0xFF1565C0),
                      size: 22),
                  Text('${f['temp']}°',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : Colors.black87)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Weekly Forecast Card ───────────────────────────────────────────────────
  Widget _buildWeeklyCard() {
    final highs = dailyForecasts.map((d) => d['high'] as int).toList();
    final lows  = dailyForecasts.map((d) => d['low']  as int).toList();
    final minT  = lows.reduce((a, b)  => a < b ? a : b).toDouble();
    final maxT  = highs.reduce((a, b) => a > b ? a : b).toDouble();

    return _sectionCard(
      title: '${dailyForecasts.length}-Day Forecast',
      child: Column(
        children: List.generate(dailyForecasts.length, (i) {
          final f = dailyForecasts[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 42,
                  child: Text(f['day'],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                Icon(f['icon'] as IconData,
                    color: const Color(0xFF1565C0), size: 22),
                Row(children: [
                  SizedBox(
                    width: 32,
                    child: Text('${f['low']}°',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ),
                  const SizedBox(width: 6),
                  _tempBar(
                      f['low'] as int, f['high'] as int, minT, maxT),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 32,
                    child: Text('${f['high']}°',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ]),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _tempBar(int low, int high, double minT, double maxT) {
    final range = (maxT - minT) == 0 ? 1.0 : maxT - minT;
    final start = ((low  - minT) / range).clamp(0.0, 1.0);
    final end   = ((high - minT) / range).clamp(0.0, 1.0);

    return SizedBox(
      width: 80,
      height: 5,
      child: LayoutBuilder(builder: (ctx, box) {
        return Stack(children: [
          Container(
            width: box.maxWidth,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Positioned(
            left: box.maxWidth * start,
            width: (box.maxWidth * (end - start)).clamp(8.0, box.maxWidth),
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF1565C0)],
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  // ── Bottom Stats Row ───────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
            child: _statTile(
                Icons.wb_twilight_outlined, 'Sunrise', sunrise)),
        const SizedBox(width: 10),
        Expanded(
            child:
                _statTile(Icons.nights_stay_outlined, 'Sunset', sunset)),
        const SizedBox(width: 10),
        Expanded(
            child: _statTile(Icons.visibility_outlined, 'Visibility',
                '${visibility.toStringAsFixed(0)}km')),
        const SizedBox(width: 10),
        Expanded(
            child:
                _statTile(Icons.wb_shade, 'UV Index', '$uvIndex')),
      ],
    );
  }

  Widget _statTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Section Card Wrapper ───────────────────────────────────────────────────
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black87)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}