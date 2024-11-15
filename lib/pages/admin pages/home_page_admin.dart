import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/pages/admin%20pages/ads_panel.dart';

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

  final List<String> categories = [
    "All", "Delivery", "Car Driver", "Ambulance", "Mechanic", "Car wash",
    "Car rent", "Diagnostic auto", "Electricite auto", "SoS remorquage",
    "Tire Repair", "Car Charger", "Car windows"
  ];
  final List<String> countries = [
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
                    color: Colors.orange,
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
                        // Action for Calls stats
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
  return Container(
    height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
    child: Column(
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: countries.length + 1, // Adding 1 for the "+" button
            itemBuilder: (context, index) {
              if (index == countries.length) {
                // "+" button
                return GestureDetector(
                  onTap: () async {
                    final newCountry = await _showAddCountryDialog();
                    if (newCountry != null && newCountry.isNotEmpty) {
                      setState(() {
                        countries.add(newCountry);
                      });
                    }
                  },
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
                // Regular country chips
                final country = countries[index];
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
              }
            },
          ),
        ),
      ],
    ),
  );
}

// Dialog to add a new country
Future<String?> _showAddCountryDialog() async {
  String? newCountry;
  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter new country'),
        content: TextField(
          onChanged: (value) {
            newCountry = value;
          },
          decoration: const InputDecoration(hintText: "Country name"),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              Navigator.of(context).pop(newCountry);
            },
          ),
        ],
      );
    },
  );
}


}
