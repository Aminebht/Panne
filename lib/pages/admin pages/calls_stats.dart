import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:panne_auto/componant/spinning_img.dart';

class CallsStatsPage extends StatefulWidget {
  @override
  _CallsStatsPageState createState() => _CallsStatsPageState();
}

class _CallsStatsPageState extends State<CallsStatsPage> {
  String selectedPeriod = "All Time";
  String selectedCategory = "All";
  String selectedCountry = "All";
  String selectedSort = "descending";
  final List<String> countries = [
    "All", "Tunisia", "Algeria"
  ];

  List<Map<String, dynamic>> artisans = [];
  int currentPage = 1;
  int itemsPerPage = 10;
  bool isLoading = false;
  String? error;
  Map<String, int> connectedArtisanCache = {};

  @override
  void initState() {
    super.initState();
    fetchArtisansData();
  }

  Future<void> fetchArtisansData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      List<Map<String, dynamic>> newArtisans = [];
      DateTimeRange? dateRange = getPeriodDateRange();

      if (selectedCategory == "All") {
        // Handle "All" category case
        Query query = FirebaseFirestore.instance
            .collection('users')
            .where('user type', isEqualTo: 'Artisan');

        if (selectedCountry != "All") {
          query = query.where('country', isEqualTo: selectedCountry);
        }

        QuerySnapshot usersSnapshot = await query.get();
        
        for (var userDoc in usersSnapshot.docs) {
          await processArtisanDocument(userDoc, newArtisans, dateRange);
        }
      } else {
        // Handle specific category case
        QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
            .collection('jobs')
            .where('job type', isEqualTo: selectedCategory)
            .get();

        List<String> artisanIds = jobSnapshot.docs
            .map((doc) => doc['user id'] as String)
            .toList();

        // Process artisans in batches of 30
        for (int i = 0; i < artisanIds.length; i += 30) {
          final batchIds = artisanIds.sublist(
            i, 
            i + 30 > artisanIds.length ? artisanIds.length : i + 30
          );

          Query query = FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batchIds)
              .where('user type', isEqualTo: 'Artisan');

          if (selectedCountry != "All") {
            query = query.where('country', isEqualTo: selectedCountry);
          }

          QuerySnapshot batchSnapshot = await query.get();
          
          for (var userDoc in batchSnapshot.docs) {
            await processArtisanDocument(userDoc, newArtisans, dateRange);
          }
        }
      }

      // Sort the artisans
      sortArtisans(newArtisans);

      setState(() {
        artisans = newArtisans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error fetching data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> processArtisanDocument(
    DocumentSnapshot userDoc,
    List<Map<String, dynamic>> artisansList,
    DateTimeRange? dateRange
  ) async {
    var artisanId = userDoc.id;
    var artisanData = userDoc.data() as Map<String, dynamic>;

    // Build calls query
    Query callsQuery = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: artisanId);

    QuerySnapshot callsSnapshot = await callsQuery.get();
    
    if (callsSnapshot.docs.isNotEmpty) {
      // Filter calls based on date range if specified
      List<Timestamp> callDates = callsSnapshot.docs
          .map((doc) => doc.get('sentAt') as Timestamp)
          .where((timestamp) => dateRange == null || 
              _isDateInRange(timestamp.toDate(), dateRange))
          .toList();

      if (callDates.isNotEmpty) {
        artisansList.add({
          'name': artisanData['fullName'] ?? 'Unknown',
          'calls': callDates.length,
          'category': artisanData['category'] ?? 'Unknown',
          'country': artisanData['country'] ?? 'Unknown',
          'callDates': callDates,
        });
      }
    }
  }

  // Rest of the existing helper methods remain the same
  DateTimeRange? getPeriodDateRange() {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case "Last 7 days":
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case "Last 30 days":
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case "This month":
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case "Last three months":
        return DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
      case "Last year":
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      default:
        return null;
    }
  }

  bool _isDateInRange(DateTime date, DateTimeRange range) {
    DateTime startDate = DateTime(range.start.year, range.start.month, range.start.day);
    DateTime endDate = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.compareTo(startDate) >= 0 && 
           normalizedDate.compareTo(endDate) <= 0;
  }

  void sortArtisans(List<Map<String, dynamic>> data) {
    switch (selectedSort) {
      case "ascending":
        data.sort((a, b) => a['calls'].compareTo(b['calls']));
        break;
      case "descending":
        data.sort((a, b) => b['calls'].compareTo(a['calls']));
        break;
      case "by alphabet":
        data.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    int start = (currentPage - 1) * itemsPerPage;
    int end = (start + itemsPerPage) > artisans.length ? artisans.length : (start + itemsPerPage);
    List<Map<String, dynamic>> currentArtisans = artisans.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calls stats"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Color(0xFFF3F3F3),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 8),
                _buildSort(),
                const SizedBox(height: 15),
                if (isLoading)
                  SpinningImage()
                else if (error != null)
                  Text(error!, style: TextStyle(color: Colors.red))
                else if (artisans.isEmpty)
                  const Text("No data found")
                else
                  _buildTable(currentArtisans),
                const SizedBox(height: 15),
                if (!isLoading && artisans.isNotEmpty)
                  _buildPagination(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Filters", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          // Select Period Section
          Text("Select Period", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          
          Wrap(
            spacing: 9,
            children: [
              _buildFilterChip("Select Period", ["All Time","Last 7 days","Last 30 days", "This month", "Last three months","Last year"], selectedPeriod, (value) {
                setState(() {
                  selectedPeriod = value;
                });
              }),
            ],
          ),

          // Select Category Section
          Text("Select category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          
          Wrap(
            spacing: 9,
            children: [
              _buildFilterChip("Select category", ["All", "Delivery", "Car Driver", "Ambulance", "Mechanic", "Car Wash","Car rent", "Diagnostic auto", "Electricite auto", "SoS remorquage","Tire Repair", "Car Charger", "Car windows"], selectedCategory, (value) {
                setState(() {
                  selectedCategory = value;
                });
              }),
            ],
          ),
          // Choose Country Section
          Text("Choose Country", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 9),
          _buildCountrySection(),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () async {
                await fetchArtisansData();
              },
              child: const Text("Filter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF235A81),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSort() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sort", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            children: [
              _buildFilterChip("Select category", ["descending", "ascending", "by alphabet"], selectedSort, (value) {
                setState(() {
                  selectedSort = value;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Container(
      color: Colors.white,
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: IntrinsicColumnWidth(flex: 2),  // Artisant column
          1: IntrinsicColumnWidth(flex: 1),  // Calls received column
        },
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: Color(0xFFEDF2F7),
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "Artisant",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "Calls received",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          // Data rows
          ...data.map((artisan) => TableRow(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  artisan["name"],
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  artisan["calls"].toString(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          )).toList(),
        ],
      ),
    ),
  );
}

  Widget _buildPagination() {
    int totalPages = (artisans.length / itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_left, color: currentPage > 1 ? Colors.orange : Colors.grey),
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    currentPage--;
                  });
                }
              : null,
        ),
        Text(
          "$currentPage of $totalPages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.arrow_right, color: currentPage < totalPages ? Colors.orange : Colors.grey),
          onPressed: currentPage < totalPages
              ? () {
                  setState(() {
                    currentPage++;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String title, List<String> options, String selectedOption, Function(String) onSelected) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selectedOption;

          return GestureDetector(
            onTap: () {
              onSelected(option);
              sortArtisans(artisans);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
              child: Chip(
                label: Text(
                  option,
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
                    });
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