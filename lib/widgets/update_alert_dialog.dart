import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';

class UpdateAlertDialog extends StatelessWidget {
  const UpdateAlertDialog({
    Key? key,
    required this.downloadLink,
  }) : super(key: key);
  final String downloadLink;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        elevation: 10,
        backgroundColor: tkDarkBlue,
        content: SizedBox(
          height: (screenHeight * .18).h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
                child:
                    Text('Tako-Play', style: TakoTheme.darkTextTheme.headline3),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Text('New Update is available',
                    style: TakoTheme.darkTextTheme.bodyText1),
              ),
              SizedBox(
                height: 10.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MaterialButton(
                    elevation: 5,
                    color: tkLightGreen.withAlpha(200),
                    child: const Text('Update'),
                    onPressed: () => launch(downloadLink),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
