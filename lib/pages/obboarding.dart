import 'package:flutter/material.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffEDF0E7),
      body: Container(
        margin: EdgeInsets.only(top: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset("images/tainghe.png"),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
              'Explore\nThe Best\nProducts',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 40 ),
            ),
            ),
            SizedBox(height: 20.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(right: 20.0),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: Text(
                  'Next',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20 ),
                ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
