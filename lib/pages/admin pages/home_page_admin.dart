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
    "All", "Delivery", "Car Driver", "Ambulance", "Mechanic", "Car Wash",
    "Car rent", "Diagnostic auto", "Electricite auto", "SoS remorquage",
    "Tire Repair", "Car Charger", "Car windows"
  ];

  String selectedCategory = "All";
  
  // Adding cache maps to store counts for each category to avoid redundant fetching
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
      final connectedClientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user type', isEqualTo: 'Client')
          .where('isOnline', isEqualTo: true)
          .get();
      connectedClients = connectedClientsSnapshot.size;

      final totalClientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user type', isEqualTo: 'Client')
          .get();
      totalClients = totalClientsSnapshot.size;

      // Fetching "All" category counts and caching them
      connectedArtisans = await fetchConnectedArtisans("All");
      totalArtisans = await fetchTotalArtisans("All");

      setState(() {});
    } catch (e) {
      print("Error fetching data: $e");
    }finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<int> fetchConnectedArtisans(String category) async {
    if (connectedArtisanCache.containsKey(category)) {
      return connectedArtisanCache[category]!;
    }

    int result;
    if (category == "All") {
      final connectedArtisansSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user type', isEqualTo: 'Artisan')
          .where('isOnline', isEqualTo: true)
          .get();
      result = connectedArtisansSnapshot.size;
    } else {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('job type', isEqualTo: category)
          .get();

      List<String> artisanIds = jobSnapshot.docs.map((doc) => doc['user id'] as String).toList();
      result = await getCountForBatchedUserIds(artisanIds, isOnline: true);
    }

    connectedArtisanCache[category] = result;
    return result;
  }

  Future<int> fetchTotalArtisans(String category) async {
    if (totalArtisanCache.containsKey(category)) {
      return totalArtisanCache[category]!;
    }

    int result;
    if (category == "All") {
      final totalArtisansSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user type', isEqualTo: 'Artisan')
          .get();
      result = totalArtisansSnapshot.size;
    } else {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('job type', isEqualTo: category)
          .get();

      List<String> artisanIds = jobSnapshot.docs.map((doc) => doc['user id'] as String).toList();
      result = await getCountForBatchedUserIds(artisanIds);
    }

    totalArtisanCache[category] = result;
    return result;
  }

  Future<int> getCountForBatchedUserIds(List<String> userIds, {bool isOnline = false}) async {
    if (userIds.isEmpty) return 0;

    int count = 0;
    for (int i = 0; i < userIds.length; i += 30) {
      final batchIds = userIds.sublist(i, i + 30 > userIds.length ? userIds.length : i + 30);

      Query query = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .where('user type', isEqualTo: 'Artisan');

      if (isOnline) {
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
                    connectedArtisans = await fetchConnectedArtisans(category);
                    totalArtisans = await fetchTotalArtisans(category);
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
}
