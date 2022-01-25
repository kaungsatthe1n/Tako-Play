import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';

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
        SizedBox(height: screenHeight * .05),
        Container(
          margin: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
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
