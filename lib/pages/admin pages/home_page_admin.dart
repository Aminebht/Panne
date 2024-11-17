import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/pages/admin%20pages/ads_panel.dart';
import 'package:panne_auto/pages/admin%20pages/calls_stats.dart';

class HomePage_admin extends StatefulWidget {
  @override
  _HomePage_adminState createState() => _HomePage_adminState();
}

class _HomePage_adminState extends State<HomePage_admin> {
  int connectedClients = 0;
  int totalClients = 0;
  int connectedArtisans = 0;
  int totalArtisans = 0;
  bool isLoading = true;
  List<String> filteredCountries = [];
  final List<String> allCountries = [
  'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda', 'Argentina', 'Armenia', 
  'Australia', 'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 
  'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 
  'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cambodia', 'Cameroon', 'Canada', 
  'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo', 
  'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti', 'Dominica', 
  'Dominican Republic', 'East Timor', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 
  'Estonia', 'Eswatini', 'Ethiopia', 'Fiji', 'Finland', 'France', 'Gabon', 'Gambia', 'Georgia', 
  'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 
  'Honduras', 'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy', 
  'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan', 'Laos', 
  'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg', 
  'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania', 
  'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 
  'Mozambique', 'Myanmar', 'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 
  'Niger', 'Nigeria', 'North Korea', 'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau', 'Panama', 
  'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania', 
  'Russia', 'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 
  'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 
  'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 
  'South Korea', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 
  'Syria', 'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Togo', 'Tonga', 'Trinidad and Tobago', 
  'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 'United Arab Emirates', 
  'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu', 'Vatican City', 'Venezuela', 
  'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe'
];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'settings'; // Collection name in Firestore
  final String documentId = 'countries'; // Document ID for countries list
  List<String> selectedCountries = [];
  final TextEditingController _searchController = TextEditingController();
  final List<String> categories = [
    "All", "Delivery", "Car Driver", "Ambulance", "Mechanic", "Car wash",
    "Car rent", "Diagnostic auto", "Electricite auto", "SoS remorquage",
    "Tire Repair", "Car Charger", "Car windows"
  ];
  List<String> countries = [
    "All", "Tunisia", "Algeria"
  ];

  String selectedCategory = "All";
  String selectedCountry = "All";

  Map<String, int> connectedArtisanCache = {};
  Map<String, int> totalArtisanCache = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      connectedClients = await fetchClientCount(online: true);
      totalClients = await fetchClientCount();
      
      connectedArtisans = await fetchArtisanCount( online: true);
      totalArtisans = await fetchArtisanCount();

      setState(() {});
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<int> fetchClientCount({bool online = false}) async {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('user type', isEqualTo: 'Client');

    if (selectedCountry != "All") {
      query = query.where('country', isEqualTo: selectedCountry);
    }
    if (online) {
      query = query.where('isOnline', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.size;
  }

  Future<int> fetchArtisanCount({bool online = false}) async {
    // Create a composite key that includes both category and country
    String cacheKey = '${selectedCategory}_${selectedCountry}';
    // Only use cache for total counts (not online counts) and if cache exists
    if (connectedArtisanCache.containsKey(cacheKey) && !online) {
      return connectedArtisanCache[cacheKey]!;
    }

    int count = 0;
    QuerySnapshot jobSnapshot;

    if (selectedCategory == "All") {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('user type', isEqualTo: 'Artisan');

      if (selectedCountry != "All") {
        query = query.where('country', isEqualTo: selectedCountry);
      }
      if (online) {
        query = query.where('isOnline', isEqualTo: true);
      }

      jobSnapshot = await query.get();
      count = jobSnapshot.size;
    } else {
      // First get all artisans for the selected category
      jobSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('job type', isEqualTo: selectedCategory)
          .get();

      List<String> artisanIds = jobSnapshot.docs
          .map((doc) => doc['user id'] as String)
          .toList();
      
      // Then filter by country and online status
      count = await getCountForBatchedUserIds(artisanIds, selectedCountry, online: online);
    }

    // Only cache the total counts (not online counts)
    if (!online) {
      connectedArtisanCache[cacheKey] = count;
    }

    return count;
  }

  Future<int> getCountForBatchedUserIds(List<String> userIds, String country, {bool online = false}) async {
    if (userIds.isEmpty) return 0;
    
    int count = 0;
    for (int i = 0; i < userIds.length; i += 30) {
      final batchIds = userIds.sublist(i, i + 30 > userIds.length ? userIds.length : i + 30);

      Query query = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .where('user type', isEqualTo: 'Artisan');

      if (country != "All") {
        query = query.where('country', isEqualTo: country);
      }
      if (online) {
        query = query.where('isOnline', isEqualTo: true);
      }

      QuerySnapshot artisanSnapshot = await query.get();
      count += artisanSnapshot.size;
    }

    return count;
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading?Center(child: SpinningImage(),):Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Marhbe , Ramzi",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                    Text("Overview"),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE29100),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned(
            top: 70, // Adjust this to control vertical position
            left: MediaQuery.of(context).size.width*0.1, // Adjust this to control horizontal position
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE29100),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CallsStatsPage()),
                            );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE29100),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Calls stats",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AdvertisingPanelPage()),
                            );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE29100),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Advertising panel",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

 // Rounded corners for the dialog
    
         
          

                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 54),
            const Text("Choose a country", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            _buildCountrySection(),
            const Text("Client", style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 40),
            Row(
              children: [
                _buildInfoCard("Connected", connectedClients, const Color(0xFF319595)),
                const SizedBox(width: 6),
                _buildInfoCard("Total", totalClients, const Color(0xFF235A81)),
              ],
            ),
            const SizedBox(height: 40),
            const Text("Artisant", style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 30),
            _buildCategorySection(),
            const SizedBox(height: 23),
            Row(
              children: [
                _buildInfoCard("Connected", connectedArtisans, const Color(0xFF319595)),
                const SizedBox(width: 6),
                _buildInfoCard("Total", totalArtisans, const Color(0xFF235A81)),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        height: 110,
        width: 150,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                value.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      selectedCategory = category;
                    });
                    connectedArtisans = await fetchArtisanCount(online: true);
                    totalArtisans = await fetchArtisanCount();
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
                    child: Chip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFE29100),
                          fontSize: 15,
                        ),
                      ),
                      backgroundColor: isSelected ? const Color(0xFFE29100) : Colors.orange.withOpacity(0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Color(0xFFE29100),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCountrySection() {
  return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection(collectionName).doc(documentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        // Update local state if Firebase data changes
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            selectedCountries = List<String>.from(data['countries'] ?? []);
          }
        }

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedCountries.length + 1,
                  itemBuilder: (context, index) {
                    if (index == selectedCountries.length) {
                      return GestureDetector(
                        onTap: _showAddCountryDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
                          child: Chip(
                            label: const Text(
                              '+',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            backgroundColor: const Color(0xFFE29100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    } else {
                      final country = selectedCountries[index];
                      final isSelected = country == selectedCountry;

                      return GestureDetector(
                        
                  onTap: () async {
                    setState(() {
                      selectedCountry = country;
                      selectedCategory = "All";
                    });

                    // Fetch the data again after country change
                    await fetchData();
                    setState(() {});// This refetches the data for the selected country
                  },
                        onLongPress: () => _showRemoveConfirmation(country),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
                          child: Chip(
                            label: Text(
                              country,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFFE29100),
                                fontSize: 15,
                              ),
                            ),
                            backgroundColor: isSelected 
                                ? const Color(0xFFE29100) 
                                : Colors.orange.withOpacity(0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: Color(0xFFE29100),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
}
Future<void> _loadCountries() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(collectionName)
          .doc(documentId)
          .get();

        setState(() {
          countries = List<String>.from(doc.get('countries') ?? []);
        });
    } catch (e) {
      print('Error loading countries: $e');
      // Handle error appropriately
    }
  }

  // Update countries in Firestore
  Future<void> _updateCountriesInFirestore(List<String> countries) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).set({
        'countries': countries
      });
    } catch (e) {
      print('Error updating countries: $e');
      // Handle error appropriately
      // You might want to show a snackbar or alert to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating countries: $e')),
      );
    }
  }

  Future<void> _showAddCountryDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Country'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Type to search countries...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredCountries = allCountries
                              .where((country) => 
                                  country.toLowerCase().contains(value.toLowerCase()) &&
                                  !selectedCountries.contains(country))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchController.text.isEmpty ? 0 : filteredCountries.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredCountries[index]),
                            onTap: () {
                              if (!selectedCountries.contains(filteredCountries[index])) {
                                Navigator.of(context).pop(filteredCountries[index]);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) async {
      if (value != null) {
        setState(() {
          selectedCountries.add(value);
          _searchController.clear();
          filteredCountries.clear();
        });
        // Update Firestore after adding a country
        await _updateCountriesInFirestore(selectedCountries);
      }
    });
  }

  Future<void> _showRemoveConfirmation(String country) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Country'),
          content: Text('Are you sure you want to remove $country?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        setState(() {
          selectedCountries.remove(country);
          if (selectedCountry == country) {
            selectedCountry = 'All';
          }
        });
        // Update Firestore after removing a country
        await _updateCountriesInFirestore(selectedCountries);
      }
    });
  }

}
