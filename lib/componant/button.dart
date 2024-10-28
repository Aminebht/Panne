import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainButton extends StatelessWidget {
  final String name;
  const MainButton({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 308,
      height: 53,
      decoration: BoxDecoration(
        color: Color(0xFF235A81),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFF235A81), // Set the desired border color
          width: 1.0, // Set the desired border width
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
