import 'package:flutter/material.dart';
import 'package:panne_auto/konnect/konnect_api_service.dart';



class SubscriptionScreen extends StatefulWidget {
  final String DropdownValue;
  SubscriptionScreen({required this.DropdownValue});
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int selectedIndex = 1; // Default to 6 months
  final KonnectApiService _apiService = KonnectApiService();
  String selectedMethod = '';
  int amount = 100000; // Example amount // Variable to hold the selected price
void _initiatePayment() async {
    try {
      final response = await _apiService.sendPaymentRequest(
        context: context,
        amount: amount,
        dropdownValue: widget.DropdownValue,
      );
    } catch (e) {
      print("Error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(35, 90, 129, 1),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow effect
            Positioned(
              top: MediaQuery.of(context).size.height * 0.42,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(226, 145, 0, 0.97), // light orange glow
                      Color.fromRGBO(35, 90, 129, 1), // fade out to transparent
                    ],
                    stops: [0.1, 0.73],
                  ),
                ),
              ),
            ),
            
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Image
                Container(
                  width: 300,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: AssetImage('assets/icons/tools.png'), // Replace with your image path
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Title and Description
                Text(
                  'Subscription',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 65.0),
                  child: Text(
                    'Purchase the subscription for artisans and open up your horizons to a new clientele and more flexible schedules',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 160),

                // Subscription Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSubscriptionOption(0, '1 month', '20 TND', isPopular: false),
                    SizedBox(width: 10),
                    _buildSubscriptionOption(1, '6 months', '100 TND', isPopular: true),
                    SizedBox(width: 10),
                    _buildSubscriptionOption(2, '12 months', '160 TND', isPopular: false),
                  ],
                ),
                SizedBox(height: 30),

                // Pay Button
                ElevatedButton(
                  onPressed: () {
                     _initiatePayment(); // Print the selected price
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(226, 145, 0, 1),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget for individual subscription option
  Widget _buildSubscriptionOption(int index, String duration, String price, {bool isPopular = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index; // Update selected index on tap
          amount= int.parse(price.split(' ')[0]) * 1000;
; // Update the selected price based on the option tapped
        });
      },
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Subscription option container
          Container(
            width: isPopular ? 140 : 100,
            height: isPopular ? 160 : 100,
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: index == selectedIndex
                    ? Color.fromRGBO(226, 145, 0, 1)
                    : Colors.transparent,
                width: 4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  duration,
                  style: TextStyle(fontSize: isPopular ? 22 : 18, fontWeight: FontWeight.bold, color: Color.fromRGBO(35, 90, 129, 1)),
                ),
                SizedBox(height: 5),
                Text(
                  price,
                  style: TextStyle(fontSize: isPopular ? 18 : 14, color: Color.fromRGBO(35, 90, 129, 1), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Popular badge, always on top
          if (isPopular)
            Positioned(
              top: -15,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(226, 145, 0, 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
