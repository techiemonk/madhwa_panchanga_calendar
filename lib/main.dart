import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MadhwaCalendarApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'Kannada';
  DateTime _selectedDate = DateTime.now();
  bool _dailyAlertsEnabled = true;
  Map<String, dynamic>? _currentPanchanga;
  bool _isLoading = false;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  DateTime get selectedDate => _selectedDate;
  bool get dailyAlertsEnabled => _dailyAlertsEnabled;
  Map<String, dynamic>? get currentPanchanga => _currentPanchanga;
  bool get isLoading => _isLoading;

  Future<void> initSystem() async {
    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      // Select a valid date within range if today is out of range
      if (_selectedDate.isBefore(DateTime(2025, 12, 8)) || _selectedDate.isAfter(DateTime(2026, 3, 19))) {
        _selectedDate = DateTime(2025, 12, 8);
      }

      await fetchPanchangaForDate(_selectedDate);
      await _scheduleDailyPanchanga();
    } catch (e) {
      debugPrint("System Init Error: $e");
    }
  }

  Future<void> fetchPanchangaForDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();
    String docId = DateFormat('yyyy-MM-dd').format(date); 
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('panchanga_data').doc(docId)
          .get(const GetOptions(source: Source.serverAndCache));
      _currentPanchanga = snapshot.exists ? snapshot.data() : null;
    } catch (e) {
      debugPrint("Firebase Fetch Error: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    _scheduleDailyPanchanga();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchPanchangaForDate(date);
  }

  void resetToToday() {
    DateTime today = DateTime.now();
    // Only reset to today if today is within the data range
    if (today.isAfter(DateTime(2025, 12, 7)) && today.isBefore(DateTime(2026, 3, 20))) {
      _selectedDate = today;
    } else {
      _selectedDate = DateTime(2025, 12, 8);
    }
    fetchPanchangaForDate(_selectedDate);
  }

  void toggleDailyAlerts(bool value) {
    _dailyAlertsEnabled = value;
    if (value) { _scheduleDailyPanchanga(); } else { flutterLocalNotificationsPlugin.cancelAll(); }
    notifyListeners();
  }

  String translateData(String category, dynamic value) {
    if (value == null) return "---";
    String val = value.toString().trim();
    if (_language == 'English') return val;

    Map<String, Map<String, String>> translations = {
      "samvastara": {"Sri Vishvavasu samvastara": _language == 'Kannada' ? "ಶ್ರೀ ವಿಶ್ವಾವಸು ಸಂವತ್ಸರ" : "श्री विश्ववसु संवत्सर"},
      "ayana": {"Dakshinayaana": _language == 'Kannada' ? "ದಕ್ಷಿಣಾಯಣ" : "दक्षिणायण", "Uttarayana": _language == 'Kannada' ? "ಉತ್ತರಾಯಣ" : "उत्तरायण"},
      "rutu": {"Hemanta rutu": _language == 'Kannada' ? "ಹೇಮಂತ ಋತು" : "हेमन्त ऋतु", "Magha rutu": _language == 'Kannada' ? "ಶಿಶಿರ ಋತು" : "शिशिर ऋतु"},
      "masa": {"Margashira masa": _language == 'Kannada' ? "ಮಾರ್ಗಶಿರ ಮಾಸ" : "ಮಾರ್ಗಶೀರ್ಷ ಮಾಸ", "Pushya masa": _language == 'Kannada' ? "ಪುಷ್ಯ ಮಾಸ" : "ಪುಷ್ಯ ಮಾಸ", "Shishira masa": _language == 'Kannada' ? "ಮಾಘ ಮಾಸ" : "ಮಾಘ ಮಾಸ", "Phalguna masa": _language == 'Kannada' ? "ಫಾಲ್ಗುಣ ಮಾಸ" : "ಫಾಲ್ಗುಣ ಮಾಸ"},
      "paksha": {"Krishna paksha": _language == 'Kannada' ? "ಕೃಷ್ಣ ಪಕ್ಷ" : "ಕೃಷ್ಣ ಪಕ್ಷ", "Shukla paksha": _language == 'Kannada' ? "ಶುಕ್ಲ ಪಕ್ಷ" : "ಶುಕ್ಲ ಪಕ್ಷ"},
      "tithi": {
        "Pratipada Tithi": _language == 'Kannada' ? "ಪಾಡ್ಯ" : "प्रतिपदा", "Dwiteeya Tithi": _language == 'Kannada' ? "ಬಿದಿಗೆ" : "द्वितीया", "Truteeya Tithi": _language == 'Kannada' ? "ತದಿಗೆ" : "तृतीया",
        "Chaturthi Tithi": _language == 'Kannada' ? "ಚತುರ್ಥಿ" : "चतुर्थी", "Panchami Tithi": _language == 'Kannada' ? "ಪಂಚಮಿ" : "पञ्चमी", "Shashti Tithi": _language == 'Kannada' ? "ಷಷ್ಠಿ" : "षष्ठी",
        "Saptami Tithi": _language == 'Kannada' ? "ಸಪ್ತಮಿ" : "सप्तमी", "Ashtami Tithi": _language == 'Kannada' ? "ಅಷ್ಟಮಿ" : "अष्टमी", "Navami Tithi": _language == 'Kannada' ? "ನವಮಿ" : "नवमी",
        "Dashami Tithi": _language == 'Kannada' ? "ದಶಮಿ" : "दशमी", "Ekadashi Tithi": _language == 'Kannada' ? "ಏಕಾದಶಿ" : "एकादशी", "Dwadashi Tithi": _language == 'Kannada' ? "ದ್ವಾದಶಿ" : "द्वादशी",
        "Trayodashi Tithi": _language == 'Kannada' ? "ತ್ರಯೋದಶಿ" : "त्रयोदशी", "Chaturdashi Tithi": _language == 'Kannada' ? "ಚತುರ್ದಶಿ" : "चतुर्दशी", "Amavasya Tithi": _language == 'Kannada' ? "ಅಮಾವಾಸ್ಯೆ" : "अमावास्या", "Hunnime Tithi": _language == 'Kannada' ? "ಹುಣ್ಣಿಮೆ" : "पूर्णिमा",
      },
      "nakshatra": {
        "Ashwini nakshatra": _language == 'Kannada' ? "ಅಶ್ವಿನಿ" : "अश्विनी", "Bharani nakshatra": _language == 'Kannada' ? "ಭರಣಿ" : "भरणी", "Kruttika nakshatra": _language == 'Kannada' ? "ಕೃತ್ತಿಕಾ" : "कृत्तिका",
        "Rohini nakshatra": _language == 'Kannada' ? "ರೋಹಿಣಿ" : "रोहिणी", "Mrugashira nakshatra": _language == 'Kannada' ? "ಮೃಗಶಿರ" : "मृगशिरा", "Ardhraa nakshatra": _language == 'Kannada' ? "ಆರಿದ್ರ" : "आर्द्रा",
        "Punarvasu nakshatra": _language == 'Kannada' ? "ಪುನರ್ವಸು" : "पुनर्वसु", "Pushya nakshatra": _language == 'Kannada' ? "ಪುಷ್ಯ" : "पुष्य", "Ashlesha nakshatra": _language == 'Kannada' ? "ಆಶ್ಲೇಷ" : "आश्लेषा",
        "Magha nakshatra": _language == 'Kannada' ? "ಮಘ" : "मघा", "PoorvaPhalguni nakshatra": _language == 'Kannada' ? "ಪುಬ್ಬಾ" : "पूर्वाफाल्गुनी", "Anuradha nakshatra": _language == 'Kannada' ? "ಅನುರಾಧ" : "अनुराधा",
      },
      "yoga": {
        "Brahma yoga": _language == 'Kannada' ? "ಬ್ರಹ್ಮ" : "ब्रह्म", "Aindra yoga": _language == 'Kannada' ? "ಐಂದ್ರ" : "ऐन्द्र", "Vaidhruti yoga": _language == 'Kannada' ? "ವೈಧೃತಿ" : "वैधृति",
      },
      "karana": {
        "Bava karna": _language == 'Kannada' ? "ಬವ" : "बव", "Balava karna": _language == 'Kannada' ? "ಬಾಲವ" : "बालव",
      }
    };
    return translations[category]?[val] ?? val; 
  }

  Future<void> showInstantTestNotification() async {
    if (_currentPanchanga == null) return;
    String tithi = translateData('tithi', _currentPanchanga!['tithi']);
    String nak = translateData('nakshatra', _currentPanchanga!['nakshatra']);
    String yoga = translateData('yoga', _currentPanchanga!['yoga']);
    String karana = translateData('karana', _currentPanchanga!['karana']);
    String desc = t("ತಿಥಿ: $tithi, ನಕ್ಷತ್ರ: $nak, ಯೋಗ: $yoga, ಕರಣ: $karana", "Tithi: $tithi, Nakshatra: $nak, Yoga: $yoga, Karana: $karana", "तिथि: $tithi, नक्षत्र: $nak, योग: $yoga, करण: $karana");
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('test_channel', 'Test Alerts', importance: Importance.max, priority: Priority.high);
    await flutterLocalNotificationsPlugin.show(99, t("ಮಾಧ್ವ ಪಂಚಾಂಗ", "Madhwa Panchanga", "माध्व पञ्चाङ्ग"), desc, const NotificationDetails(android: androidDetails));
  }

  Future<void> _scheduleDailyPanchanga() async {
    if (!_dailyAlertsEnabled || _currentPanchanga == null) return;
    String tithi = translateData('tithi', _currentPanchanga!['tithi']);
    String nak = translateData('nakshatra', _currentPanchanga!['nakshatra']);
    String yoga = translateData('yoga', _currentPanchanga!['yoga']);
    String karana = translateData('karana', _currentPanchanga!['karana']);
    String desc = t("ತಿಥಿ: $tithi, ನಕ್ಷತ್ರ: $nak, ಯೋಗ: $yoga, ಕರಣ: $karana", "Tithi: $tithi, Nakshatra: $nak, Yoga: $yoga, Karana: $karana", "तिथि: $tithi, नक्षत्र: $nak, योग: $yoga, करण: $karana");
    await flutterLocalNotificationsPlugin.zonedSchedule(0, t("ಶುಭೋದಯ - ಪಂಚಾಂಗ", "Good Morning", "सुप्रभातम्"), desc, _nextInstanceOfSixAM(),
      const NotificationDetails(android: AndroidNotificationDetails('daily_id', 'Daily Panchanga', importance: Importance.max, priority: Priority.high)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.time);
  }

  tz.TZDateTime _nextInstanceOfSixAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 6, 0);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
    return scheduledDate;
  }

  String t(String kn, String en, String sa) {
    if (_language == 'English') return en;
    if (_language == 'Sanskrit') return sa;
    return kn;
  }
}

class MadhwaCalendarApp extends StatelessWidget {
  const MadhwaCalendarApp({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return MaterialApp(debugShowCheckedModeBanner: false, themeMode: state.themeMode, theme: ThemeData(useMaterial3: true, textTheme: GoogleFonts.notoSansKannadaTextTheme(), colorSchemeSeed: Colors.orange), darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, textTheme: GoogleFonts.notoSansKannadaTextTheme(ThemeData.dark().textTheme), colorSchemeSeed: Colors.orange), home: const SplashScreen());
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _startApp(); }
  _startApp() async { await Provider.of<AppState>(context, listen: false).initSystem(); if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainNavigationScreen())); }
  @override
  Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.orange, body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.wb_sunny, size: 100, color: Colors.white), const SizedBox(height: 20), Text("ಮಾಧ್ವ ಪಂಚಾಂಗ", style: GoogleFonts.notoSansKannada(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 40), const CircularProgressIndicator(color: Colors.white)]))); }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: Text(state.t("ಮಾಧ್ವ ಪಂಚಾಂಗ", "Madhwa Panchanga", "माध्व पञ्चाङ्ग")), backgroundColor: Colors.orange, actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen())))]),
      body: IndexedStack(index: _selectedIndex, children: const [PanchangaHomeScreen(), MonthlyCalendarScreen()]),
      bottomNavigationBar: NavigationBar(selectedIndex: _selectedIndex, onDestinationSelected: (i) => setState(() => _selectedIndex = i), destinations: [NavigationDestination(icon: const Icon(Icons.today), label: state.t('ಇಂದು', 'Today', 'अद्य')), NavigationDestination(icon: const Icon(Icons.calendar_month), label: state.t('ಕ್ಯಾಲೆಂಡರ್', 'Calendar', 'पञ्चाङ्ग'))]),
    );
  }
}

class PanchangaHomeScreen extends StatelessWidget {
  const PanchangaHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final d = state.currentPanchanga;
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (d == null) return const Center(child: Text("Syncing Data..."));

    return Container(decoration: BoxDecoration(gradient: LinearGradient(colors: state.themeMode == ThemeMode.light ? [Colors.orange.shade50, Colors.white] : [Colors.grey.shade900, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildHeader(state.selectedDate),
        const SizedBox(height: 10),
        _buildDetailCard(state.t("ಸಂವತ್ಸರ", "Samvatsara", "ಸಂವತ್ಸರ"), state.translateData('samvastara', d['samvastara']), Icons.calendar_month, Colors.brown),
        _buildDetailCard(state.t("ಅಯನ", "Ayana", "ಅಯನ"), state.translateData('ayana', d['aayana']), Icons.swap_calls, Colors.indigo),
        _buildDetailCard(state.t("ಋತು", "Rutu", "ಋತು"), state.translateData('rutu', d['rutu']), Icons.eco, Colors.green),
        _buildDetailCard(state.t("ಮಾಸ", "Masa", "ಮಾಸ"), state.translateData('masa', d['masa']), Icons.layers, Colors.orange),
        _buildDetailCard(state.t("ಪಕ್ಷ", "Paksha", "ಪಕ್ಷ"), state.translateData('paksha', d['paksha']), Icons.brightness_6, Colors.blueGrey),
        _buildDetailCard(state.t("ತಿಥಿ", "Tithi", "ತಿಥಿ"), state.translateData('tithi', d['tithi']), Icons.brightness_3, Colors.purple),
        _buildDetailCard(state.t("ನಕ್ಷತ್ರ", "Nakshatra", "ನಕ್ಷತ್ರ"), state.translateData('nakshatra', d['nakshatra']), Icons.auto_awesome, Colors.amber),
        _buildDetailCard(state.t("ಯೋಗ", "Yoga", "ಯೋಗ"), state.translateData('yoga', d['yoga']), Icons.all_inclusive, Colors.teal),
        _buildDetailCard(state.t("ಕರಣ", "Karana", "ಕರಣ"), state.translateData('karana', d['karana']), Icons.category, Colors.blue),
      ]));
  }
  Widget _buildHeader(DateTime date) { return Container(padding: const EdgeInsets.symmetric(vertical: 24), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(15)), child: Column(children: [Text(DateFormat('EEEE').format(date).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)), const SizedBox(height: 4), Text(DateFormat('d MMMM yyyy').format(date), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))])); }
  Widget _buildDetailCard(String l, String v, IconData i, Color c) { return Card(child: ListTile(leading: Icon(i, color: c), title: Text(l, style: const TextStyle(fontSize: 11, color: Colors.grey)), trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.bold)))); }
}

class MonthlyCalendarScreen extends StatelessWidget {
  const MonthlyCalendarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Column(children: [
      TableCalendar(
        firstDay: DateTime.utc(2025, 1, 1), 
        lastDay: DateTime.utc(2026, 12, 31), 
        focusedDay: state.selectedDate, 
        calendarFormat: CalendarFormat.month, 
        availableCalendarFormats: const {CalendarFormat.month: 'Month'}, 
        selectedDayPredicate: (d) => isSameDay(state.selectedDate, d), 
        onDaySelected: (s, f) => state.setSelectedDate(s), 
        enabledDayPredicate: (day) => day.isAfter(DateTime(2025, 12, 7)) && day.isBefore(DateTime(2026, 03, 20)),
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          disabledTextStyle: TextStyle(color: Colors.grey),
        )
      ), 
      ElevatedButton(onPressed: () => state.resetToToday(), child: Text(state.t("ಇಂದು", "Today", "अद्य")))
    ]);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: Text(state.t("ಸೆಟ್ಟಿಂಗ್ಸ್", "Settings", "निर्ಬಂಧಾಃ"))),
      body: ListView(children: [
        SwitchListTile(title: Text(state.t("ಪಂಚಾಂಗ ಎಚ್ಚರಿಕೆ", "Panchanga Alerts", "पञ्चाङ्ग सूचना")), secondary: const Icon(Icons.alarm_on), value: state.dailyAlertsEnabled, onChanged: (v) => state.toggleDailyAlerts(v)),
        ListTile(leading: const Icon(Icons.notification_important), title: Text(state.t("ಪರೀಕ್ಷಾ ಸೂಚನೆ", "Test Notification", "परीक्षण सूचना")), onTap: () => state.showInstantTestNotification()),
        const Divider(),
        SwitchListTile(title: Text(state.t("ಡಾರ್ಕ್ ಮೋಡ್", "Dark Mode", "तमोमयम्")), secondary: const Icon(Icons.dark_mode), value: state.themeMode == ThemeMode.dark, onChanged: (v) => state.toggleTheme(v)),
        Padding(padding: const EdgeInsets.all(16), child: SegmentedButton<String>(segments: const [ButtonSegment(value: 'English', label: Text('English')), ButtonSegment(value: 'Kannada', label: Text('ಕನ್ನಡ')), ButtonSegment(value: 'Sanskrit', label: Text('संस्कृतಮ್'))], selected: {state.language}, onSelectionChanged: (s) => state.setLanguage(s.first))),
        const SizedBox(height: 40),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Card(elevation: 0, color: Colors.orange.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.orange.withOpacity(0.2))), child: const Padding(padding: EdgeInsets.all(20), child: Column(children: [Icon(Icons.auto_awesome, color: Colors.orange), SizedBox(height: 10), Text("Created by @techiemonk", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)), Text("Version 1.0.4", style: TextStyle(fontSize: 12, color: Colors.grey))])))),
      ]),
    );
  }
}