import 'package:flutter/material.dart';

class BoundaryBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;

  BoundaryBox(
      this.results, this.previewH, this.previewW, this.screenH, this.screenW);

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderStrings() {
      // print("${results} results");
      return results.map((re) {
        return Stack(
          children: <Widget>[
            Positioned(
              bottom: -(screenH - 80),
              width: screenW,
              height: screenH,
              child:
              Column(
                children: [
                  // for(int i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${re["label"]} ${(re["confidence"] * 100).toStringAsFixed(0)}%",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        backgroundColor: Colors.blueGrey.shade900,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              width: screenW,
              height: screenH,
              child: Text(
                "For better result stable the camera",
                textAlign: TextAlign.center,
                style: TextStyle(
                  backgroundColor: Colors.blueGrey.shade900,
                  decorationColor: Colors.blue,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        );
      }).toList();
    }

    return Stack(
      children: _renderStrings(),
    );
  }
}