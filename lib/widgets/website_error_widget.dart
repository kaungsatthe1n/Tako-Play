import 'package:flutter/material.dart';
import '../theme/tako_theme.dart';

class WebsiteErrorWidget extends StatelessWidget {
  const WebsiteErrorWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/deku.gif'),
        SizedBox(height: 20),
        Container(
          margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          alignment: Alignment.center,
          child: Text(
            'Temporarily Down For Maintainance.',
            textAlign: TextAlign.center,
            style: TakoTheme.darkTextTheme.headline4,
          ),
        )
      ],
    );
  }
}
