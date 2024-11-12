import 'package:flutter/material.dart';
import 'package:panne_auto/pages/admin%20pages/ads_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:panne_auto/auth/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:panne_auto/functions/deleteExpiredJobs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async{
  runApp(MyApp());
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CallsStatsPage(),
    );
  }
}

class CallsStatsPage extends StatefulWidget {
  @override
  _CallsStatsPageState createState() => _CallsStatsPageState();
}

class _CallsStatsPageState extends State<CallsStatsPage> {
  String selectedPeriod = "This week";
  String selectedCategory = "All";
  String selectedCountry = "";
  String selectedSort = "ascending";

  // Placeholder data for artisans
  List<Map<String, dynamic>> artisans = [
    {"name": "Mohamed Salah", "calls": 18},
    {"name": "Alaya Ibriguigui", "calls": 47},
    {"name": "Yann Sass", "calls": 7},
    {"name": "Marwen Tej", "calls": 11},
    {"name": "Ferjani Sassi", "calls": 5},
    {"name": "Karim El Aouadhi", "calls": 9},
    {"name": "Youssef El Blaïli", "calls": 230},
    {"name": "Slimen Kshok", "calls": 2},
    {"name": "Khaled Yahia", "calls": 40},
    {"name": "Lamin Ndaw", "calls": 17},
    {"name": "Alaya Ibriguigui", "calls": 47},
    {"name": "Mohamed Salah", "calls": 18},
    {"name": "Yann Sass", "calls": 7},
    {"name": "Marwen Tej", "calls": 11},
    {"name": "Ferjani Sassi", "calls": 5},
    {"name": "Karim El Aouadhi", "calls": 9},
    {"name": "Youssef El Blaïli", "calls": 230},
  ];
  int currentPage = 1;
  int itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    // Pagination logic
    int start = (currentPage - 1) * itemsPerPage;
    int end = (start + itemsPerPage) > artisans.length ? artisans.length : (start + itemsPerPage);
    List<Map<String, dynamic>> currentArtisans = artisans.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calls stats"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdvertisingPanelPage()),
            );
          },
        ),
      ),
      body: Container(
        color: Color(0xFFF3F3F3),
        child: SingleChildScrollView( // Wrap with SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 8),
                _buildSort(),
                const SizedBox(height: 15),
                _buildTable(currentArtisans),
                const SizedBox(height: 15),
                _buildPagination(),
                const SizedBox(height: 20), // Add bottom padding
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
          Container(
            height: 35,
            width: 118,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  selectedCountry = value;
                });
              },
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Enter country name",
                hintStyle: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF9B9A96),
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: Color(0xFFE29100),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: Color(0xFFE29100),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                // Apply filters and fetch data from database
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
              _buildFilterChip("Select category", ["ascending", "descending", "by alphabet"], selectedSort, (value) {
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
}