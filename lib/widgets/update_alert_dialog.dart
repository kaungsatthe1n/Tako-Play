import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      backgroundColor: tkGradientBlue,
      contentPadding: EdgeInsets.only(top: 0.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: tkDarkBlue,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0)),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.update,
                      color: tkDarkBlue,
                      size: 35,
                    ),
                  ),
                  Text(
                    'Version Update',
                    style: TakoTheme.darkTextTheme.headline3!
                        .copyWith(color: tkDarkBlue),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text('New Version is Available'),
            ),
            SizedBox(
              height: 20.0,
            ),
            Divider(
              color: Colors.grey,
              height: 4.0,
            ),
            Row(children: <Widget>[
              Expanded(
                  child: MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(20))),
                height: 50,
                minWidth: double.infinity,
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  'Cancel',
                  style: TakoTheme.darkTextTheme.subtitle1,
                ),
              )),
              Container(
                height: 50,
                color: Colors.white,
                width: 0.4,
              ),
              Expanded(
                  child: MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.only(bottomRight: Radius.circular(20))),
                height: 50,
                minWidth: double.infinity,
                onPressed: () => launch(downloadLink),
                child: Text(
                  'Update',
                  style: TakoTheme.darkTextTheme.subtitle1,
                ),
              )),
            ])
          ],
        ),
      ),
      // child: Column(
      //   mainAxisSize: MainAxisSize.min,
      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     Container(
      //       margin: EdgeInsets.symmetric(vertical: 10.h),
      //       child:
      //           Text('Tako-Play', style: TakoTheme.darkTextTheme.headline3),
      //     ),
      //     Container(
      //       margin:
      //           const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      //       child: Text('New Update is available',
      //           style: TakoTheme.darkTextTheme.bodyText1),
      //     ),
      //     Row(
      //       mainAxisAlignment: MainAxisAlignment.end,
      //       children: [
      //         MaterialButton(
      //           elevation: 5,
      //           color: tkGradientBlue.withAlpha(200),
      //           child: Text(
      //             'Update',
      //             style: TakoTheme.darkTextTheme.subtitle2!
      //                 .copyWith(fontWeight: FontWeight.w600),
      //           ),
      //           onPressed: () => launch(downloadLink),
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
    );
  }
}
