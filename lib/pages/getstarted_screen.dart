import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panne_auto/constants.dart';
import 'package:panne_auto/pages/login_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GetStaredScreen extends StatefulWidget {
  const GetStaredScreen({super.key});

  @override
  State<GetStaredScreen> createState() => _GetStaredScreenState();
}

class _GetStaredScreenState extends State<GetStaredScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: size.height * 0.2,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  constants.logoPath,
                  fit: BoxFit.contain,
                  height: 50,
                  width: 50,
                ),
              ),
            ),
          ),
          Container(
            height: size.height * 0.5 - 55,
            child: Image.asset('assets/logos/received_1522078838645565.jpeg')
                .animate()
                .slideX(duration: Duration(milliseconds: 400))
                .then()
                .shake(duration: Duration(milliseconds: 200)),
          ),
          Container(
            child: Column(
              children: [
                Text(
                  'Welcome to',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 30),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Panne',
                      style: GoogleFonts.poppins(
                          color: Color(0xFF235A81),
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Auto',
                      style: GoogleFonts.poppins(
                          color: Color(0xFFBB6702),
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 55),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Container(
                      width: 267,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Color(0xFF235A81),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              Color(0xFF235A81), // Set the desired border color
                          width: 1.0, // Set the desired border width
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Get Started",
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Image.asset(
                                'assets/icons/icons8-next-100 1.png'),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
