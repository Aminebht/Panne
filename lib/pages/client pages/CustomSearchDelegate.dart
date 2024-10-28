import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/componant/spinning_img.dart';
import 'package:panne_auto/pages/client%20pages/details_page.dart';

class CustomSearchDelegate extends SearchDelegate<String> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // This function will show the result based on the selection
    return Container(
      child: Center(
        child: Text(query),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // This method will show the suggestions while typing
    return StreamBuilder<QuerySnapshot>(
      stream: (query != "" && query != null)
          ? _firestore
              .collection('jobs')
              .where('user name', isGreaterThanOrEqualTo: query)
              .snapshots()
          : _firestore.collection('jobs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: SpinningImage());
        } else {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          } else {
            final results = snapshot.data!.docs;
            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    results[index]['user name'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.normal),
                  ),
                  subtitle: Text(results[index]['phone number'].toString()),
                  trailing: Text(
                    results[index]['job type'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Map<String, dynamic>? data = (results[index].data() ?? {})
                        as Map<String, dynamic>?; // Provide a default value
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsPage(
                          data: data!, // Pass the data to the detail page
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        }
      },
    );
  }
}
