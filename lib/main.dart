import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_page.dart'; // Import the new HomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dirt Coin Market',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[400],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomePage(), // Use HomePage as the entry point
    );
  }
}

class DataEntryPage extends StatefulWidget {
  const DataEntryPage({super.key});

  @override
  State<DataEntryPage> createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  final TextEditingController _priceController = TextEditingController();
  String? selectedCrop;
  String? selectedCounty;
  String? selectedMetric;
  User? _currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, String?> validationErrors = {
    'crop': null,
    'metric': null,
    'price': null,
    'county': null,
  };

  final List<String> crops = [
    'Tomato', 'Potato', 'Maize', 'Carrot', 'Onion', 'Cabbage',
    'Spinach', 'Beans', 'Peas', 'Watermelon', 'Mango', 'Banana',
  ];

  final Map<String, List<String>> cropMetrics = {
    'Tomato': ['kg', 'crate'],
    'Potato': ['kg', 'sack'],
    'Maize': ['kg', 'sack'],
    'Carrot': ['kg', 'sack'],
    'Onion': ['kg', 'net bag'],
    'Cabbage': ['head', 'dozen', 'kg'],
    'Spinach': ['bunch', 'kg'],
    'Beans': ['kg', 'sack'],
    'Peas': ['kg', 'sack'],
    'Watermelon': ['piece', 'kg'],
    'Mango': ['piece', 'dozen'],
    'Banana': ['bunch', 'kg'],
  };

  final List<String> kenyanCounties = [
    "Mombasa", "Kwale", "Kilifi", "Tana River", "Lamu", "Taita Taveta", "Garissa",
    "Wajir", "Mandera", "Marsabit", "Isiolo", "Meru", "Tharaka-Nithi", "Embu",
    "Kitui", "Machakos", "Makueni", "Nyandarua", "Nyeri", "Kirinyaga", "Murang'a",
    "Kiambu", "Turkana", "West Pokot", "Samburu", "Trans Nzoia", "Uasin Gishu",
    "Elgeyo Marakwet", "Nandi", "Baringo", "Laikipia", "Nakuru", "Narok", "Kajiado",
    "Kericho", "Bomet", "Kakamega", "Vihiga", "Bungoma", "Busia", "Siaya", "Kisumu",
    "Homa Bay", "Migori", "Kisii", "Nyamira", "Nairobi City"
  ];

  final Map<String, List<String>> cropCountyPairs = {
    'Tomato': ["Mombasa", "Kwale", "Kilifi", "Tana River", "Lamu", "Taita Taveta", "Garissa", "Wajir", "Mandera", "Marsabit", "Isiolo", "Meru", "Tharaka-Nithi", "Embu", "Kitui", "Machakos", "Makueni", "Nyandarua", "Nyeri", "Kirinyaga", "Murang'a", "Kiambu", "Turkana", "West Pokot", "Samburu", "Trans Nzoia", "Uasin Gishu", "Elgeyo Marakwet", "Nandi", "Baringo", "Laikipia", "Nakuru", "Narok", "Kajiado", "Kericho", "Bomet", "Kakamega", "Vihiga", "Bungoma", "Busia", "Siaya", "Kisumu", "Homa Bay", "Migori", "Kisii", "Nyamira", "Nairobi City"],
    'Onion': ["Mombasa", "Kwale", "Kilifi", "Tana River", "Lamu", "Taita Taveta", "Garissa", "Wajir", "Mandera", "Marsabit", "Isiolo", "Meru", "Tharaka-Nithi", "Embu", "Kitui", "Machakos", "Makueni", "Nyandarua", "Nyeri", "Kirinyaga", "Murang'a", "Kiambu", "Turkana", "West Pokot", "Samburu", "Trans Nzoia", "Uasin Gishu", "Elgeyo Marakwet", "Nandi", "Baringo", "Laikipia", "Nakuru", "Narok", "Kajiado", "Kericho", "Bomet", "Kakamega", "Vihiga", "Bungoma", "Busia", "Siaya", "Kisumu", "Homa Bay", "Migori", "Kisii", "Nyamira", "Nairobi City"],
    'Potato': ['Nyandarua', 'Nakuru', 'Meru', 'Elgeyo Marakwet', 'Kiambu', 'Uasin Gishu', 'Narok', 'Bomet', 'Kericho', 'Nairobi City'],
    'Maize': ['Trans Nzoia', 'Uasin Gishu', 'Nakuru', 'Bungoma', 'Kakamega', 'Nandi', 'Bomet', 'Kisii', 'Embu', 'Machakos', 'Nairobi City'],
    'Banana': ['Kisii', 'Meru', 'Embu', "Murang'a", 'Kirinyaga', 'Kakamega', 'Kisumu', 'Migori', 'Bungoma', 'Nairobi City'],
    'Carrot': ['Nyandarua', 'Nakuru', 'Meru', 'Kiambu', 'Uasin Gishu', 'Elgeyo Marakwet', 'Nairobi City'],
    'Cabbage': ['Nyandarua', 'Kiambu', "Murang'a", 'Nakuru', 'Meru', 'Embu', 'Kirinyaga', 'Nairobi City'],
    'Spinach': ['Kiambu', "Murang'a", 'Nairobi City', 'Nakuru', 'Embu', 'Meru'],
    'Beans': ['Kakamega', 'Bungoma', 'Trans Nzoia', 'Embu', 'Meru', 'Nakuru', 'Nyeri', 'Kirinyaga', 'Nairobi City'],
    'Peas': ['Nyandarua', 'Nakuru', 'Meru', 'Kiambu', 'Uasin Gishu', 'Nairobi City'],
    'Watermelon': ['Kitui', 'Makueni', 'Taita Taveta', 'Machakos', 'Kajiado', 'Nairobi City'],
    'Mango': ['Makueni', 'Kitui', 'Embu', 'Machakos', 'Kilifi', 'Kwale', 'Nairobi City'],
  };

  late final Map<String, Map<String, Map<String, List<double>>>> priceRanges;

  @override
  void initState() {
    super.initState();
    priceRanges = _initializePriceRanges();
    _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      setState(() {
        _currentUser = userCredential.user;
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication failed: $e')),
          );
        }
      });
    }
  }

  Map<String, Map<String, Map<String, List<double>>>> _initializePriceRanges() {
    final map = <String, Map<String, Map<String, List<double>>>>{};
    for (final county in cropCountyPairs['Tomato']!) {
      map.putIfAbsent('Tomato', () => {})[county] = {
        'kg': [50.0, 120.0],
        'crate': [2500.0, 6000.0],
      };
    }
    for (final county in cropCountyPairs['Onion']!) {
      map.putIfAbsent('Onion', () => {})[county] = {
        'kg': [60.0, 140.0],
        'net bag': [600.0, 1400.0],
      };
    }
    final defaultPrices = {
      'Potato': {'kg': [30.0, 90.0], 'sack': [1500.0, 4500.0]},
      'Maize': {'kg': [25.0, 75.0], 'sack': [1500.0, 3000.0]},
      'Banana': {'bunch': [100.0, 300.0], 'kg': [50.0, 150.0]},
      'Carrot': {'kg': [40.0, 110.0], 'sack': [2000.0, 5500.0]},
      'Cabbage': {'head': [20.0, 50.0], 'dozen': [200.0, 500.0], 'kg': [30.0, 60.0]},
      'Spinach': {'bunch': [10.0, 30.0], 'kg': [20.0, 70.0]},
      'Beans': {'kg': [70.0, 150.0], 'sack': [4200.0, 9000.0]},
      'Peas': {'kg': [80.0, 160.0], 'sack': [4800.0, 9600.0]},
      'Watermelon': {'piece': [50.0, 150.0], 'kg': [15.0, 45.0]},
      'Mango': {'piece': [10.0, 30.0], 'dozen': [100.0, 300.0]},
    };
    for (final crop in cropCountyPairs.keys) {
      if (crop == 'Tomato' || crop == 'Onion') continue;
      map.putIfAbsent(crop, () => {});
      for (final county in cropCountyPairs[crop]!) {
        map[crop]![county] = defaultPrices[crop]!;
      }
    }
    return map;
  }

  Future<bool> verifySubmission(String? crop, String? county, String? metric, double price) async {
    if (price <= 0 || price > 100000) {
      setState(() {
        validationErrors['price'] = 'Price must be positive and reasonable.';
      });
      return false;
    }
    if (crop == null || county == null || !cropCountyPairs.containsKey(crop) || !cropCountyPairs[crop]!.contains(county)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid crop-county pair.')),
      );
      return false;
    }
    if (metric == null || !priceRanges.containsKey(crop) || !priceRanges[crop]!.containsKey(county) || !priceRanges[crop]![county]!.containsKey(metric)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price data unavailable for this crop-county-metric pair.')),
      );
      return false;
    }
    final range = priceRanges[crop]![county]![metric]!;
    if (price < range[0] || price > range[1]) {
      setState(() {
        validationErrors['price'] = 'Price out of range (${range[0]}–${range[1]} KES).';
      });
      return false;
    }
    try {
      final now = DateTime.now();
      final recentSubmissions = await _firestore
          .collection('submissions')
          .where('crop', isEqualTo: crop)
          .where('county', isEqualTo: county)
          .where('metric', isEqualTo: metric)
          .where('userId', isEqualTo: _currentUser?.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(now.subtract(Duration(hours: 24))))
          .get();
      if (recentSubmissions.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$crop ($metric) in $county already submitted recently.')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying submission: $e')),
      );
      return false;
    }
    return true;
  }

  void _showCropCountyPairs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valid Crop-County Pairs'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cropCountyPairs.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '${entry.key}: ${entry.value.join(', ')}',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitData() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, authenticating...')),
      );
      return;
    }

    setState(() {
      validationErrors = {
        'crop': null,
        'metric': null,
        'price': null,
        'county': null,
      };
    });

    bool isValid = true;
    if (selectedCrop == null) {
      setState(() {
        validationErrors['crop'] = 'Please select a crop.';
      });
      isValid = false;
    }
    if (selectedMetric == null) {
      setState(() {
        validationErrors['metric'] = 'Please select a metric.';
      });
      isValid = false;
    }
    if (_priceController.text.isEmpty) {
      setState(() {
        validationErrors['price'] = 'Please enter a price.';
      });
      isValid = false;
    }
    if (selectedCounty == null) {
      setState(() {
        validationErrors['county'] = 'Please select a county.';
      });
      isValid = false;
    }

    if (!isValid) {
      return;
    }

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    try {
      final submissionsToday = await _firestore
          .collection('submissions')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get();
      const maxSubmissions = 3;
      if ((submissionsToday.count ?? 0) >= maxSubmissions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have reached the max of 3 submissions today.')),
        );
        return;
      }

      final pendingExists = await _firestore
          .collection('submissions')
          .where('crop', isEqualTo: selectedCrop)
          .where('metric', isEqualTo: selectedMetric)
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      if (pendingExists.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$selectedCrop ($selectedMetric) is already pending verification.')),
        );
        return;
      }

      double price = double.tryParse(_priceController.text) ?? 0.0;

      if (!await verifySubmission(selectedCrop, selectedCounty, selectedMetric, price)) {
        return;
      }

      final submission = {
        'crop': selectedCrop,
        'county': selectedCounty,
        'metric': selectedMetric,
        'price': price,
        'timestamp': Timestamp.now(),
        'status': 'pending',
        'userId': _currentUser!.uid,
      };
      final docRef = await _firestore.collection('submissions').add(submission);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submitted $selectedCrop ($selectedMetric) in $selectedCounty. Awaiting verification.')),
      );

      await docRef.update({'status': 'verified'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$selectedCrop ($selectedMetric) submission verified! 1 coin added.')),
      );

      setState(() {
        selectedCrop = null;
        selectedCounty = null;
        selectedMetric = null;
        _priceController.clear();
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An index is required for this query. Please create it in the Firebase Console.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableMetrics = selectedCrop != null ? cropMetrics[selectedCrop]! : <String>[];
    final availableCounties = selectedCrop != null ? cropCountyPairs[selectedCrop]! : kenyanCounties;

    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final submissionsStream = _firestore
        .collection('submissions')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: submissionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading submissions: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data!.docs;
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final submissionsToday = submissions
            .where((doc) =>
                (doc['timestamp'] as Timestamp).toDate().isAfter(startOfDay))
            .length;
        const maxSubmissions = 3;
        final canSubmit = submissionsToday < maxSubmissions;
        final activeCoins = submissions
            .where((doc) => doc['status'] == 'verified')
            .length
            .toDouble();
        final pendingCoins = submissions
            .where((doc) => doc['status'] == 'pending')
            .length
            .toDouble();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dirt Coin Market'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Coins: ${activeCoins.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pending Coins: ${pendingCoins.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Entries today: $submissionsToday / $maxSubmissions',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _showCropCountyPairs,
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text(
                          'View Pairs',
                          style: TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  color: Colors.lightBlue[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      'Earn by Sharing! 🌽 Submit Grocery Prices & Win Coins!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCrop,
                                decoration: InputDecoration(
                                  labelText: 'Select Crop',
                                  border: const OutlineInputBorder(),
                                  errorText: validationErrors['crop'],
                                ),
                                items: crops.map((crop) {
                                  return DropdownMenuItem<String>(value: crop, child: Text(crop));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCrop = value;
                                    selectedMetric = null;
                                    selectedCounty = null;
                                    validationErrors['crop'] = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedMetric,
                                decoration: InputDecoration(
                                  labelText: 'Select Metric',
                                  border: const OutlineInputBorder(),
                                  errorText: validationErrors['metric'],
                                  helperText: selectedCrop != null
                                      ? 'Available: ${cropMetrics[selectedCrop]!.join(', ')}'
                                      : null,
                                ),
                                items: availableMetrics.map((metric) {
                                  return DropdownMenuItem<String>(value: metric, child: Text(metric));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedMetric = value;
                                    validationErrors['metric'] = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Price per ${selectedMetric ?? "unit"}',
                                  border: const OutlineInputBorder(),
                                  errorText: validationErrors['price'],
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    validationErrors['price'] = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCounty,
                                decoration: InputDecoration(
                                  labelText: 'Select County',
                                  border: const OutlineInputBorder(),
                                  errorText: validationErrors['county'],
                                ),
                                items: availableCounties.map((county) {
                                  return DropdownMenuItem<String>(value: county, child: Text(county));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCounty = value;
                                    validationErrors['county'] = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: canSubmit ? _submitData : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue[600],
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'Submission History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: submissions.isEmpty
                      ? const Center(child: Text('No submissions yet.'))
                      : ListView.builder(
                          itemCount: submissions.length,
                          itemBuilder: (context, index) {
                            final submission = submissions[index].data() as Map<String, dynamic>;
                            final timestamp = DateFormat('yyyy-MM-dd HH:mm')
                                .format((submission['timestamp'] as Timestamp).toDate());
                            final status = submission['status'] == 'pending'
                                ? 'Pending'
                                : 'Verified';

                            String priceMovement = '';
                            if (status == 'Verified') {
                              final range = priceRanges[submission['crop']]![submission['county']]![submission['metric']]!;
                              final midpoint = (range[0] + range[1]) / 2;
                              final price = submission['price'] as double;
                              if (price > midpoint) {
                                priceMovement = '📈';
                              } else if (price < midpoint) {
                                priceMovement = '📉';
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                title: Text(
                                  '${submission['crop']} in ${submission['county']} $priceMovement',
                                ),
                                subtitle: Text(
                                  'Price: ${submission['price']} KES/${submission['metric']}\nTime: $timestamp\nStatus: $status',
                                ),
                                trailing: Icon(
                                  submission['status'] == 'pending'
                                      ? Icons.hourglass_empty
                                      : Icons.check_circle,
                                  color: submission['status'] == 'pending'
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}