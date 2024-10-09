import 'package:flutter/material.dart';
import '../../widget/content_model.dart';
import '../../widget/widget_support.dart';

class NurseOnboard extends StatefulWidget {
  const NurseOnboard({super.key});

  @override
  State<NurseOnboard> createState() => _NurseOnboardState();
}

class _NurseOnboardState extends State<NurseOnboard> {
  int currentIndex = 0;
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: nursesContents.length,
              onPageChanged: (int index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (_, i) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
                  child: Column(
                    children: [
                      Image.asset(
                        nursesContents[i].image,
                        height: 450,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.fill,
                      ),
                      const SizedBox(
                        height: 40.0,
                      ),
                      Text(
                        nursesContents[i].title,
                        style: AppWidget.semiBoldTextFieldStyle(),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        nursesContents[i].description,
                        style: AppWidget.lightTextFieldStyle(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              nursesContents.length,
                  (index) => buildDot(index, context),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (currentIndex == nursesContents.length - 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NurseOnboard()),
                );
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.bounceIn,
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              height: 60,
              margin: const EdgeInsets.all(40),
              width: double.infinity,
              child: Center(
                child: Text(
                  currentIndex == nursesContents.length - 1 ? "Start" : "Next",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10.0,
      width: currentIndex == index ? 18 : 7,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: currentIndex == index ? AppColors.primaryColor : AppColors.secondaryColor,
      ),
    );
  }
}


