import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../helpers/network_manager.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 80,
          ),
          const SizedBox(height: 3),
          Text(
            'Oops !',
            style: TakoTheme.darkTextTheme.headline1,
          ),
          const SizedBox(height: 15),
          Text(
            'There is no internet connection',
            style: TakoTheme.darkTextTheme.subtitle2,
          ),
          const SizedBox(height: 10),
          Text(
            'Please check your internet connection',
            style: TakoTheme.darkTextTheme.subtitle2,
          ),
          const SizedBox(height: 15),
          MaterialButton(
            onPressed: _onTryAgainPressed,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: tkGradientBlue,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _onTryAgainPressed() {
    // Manually check if connected to internet
    Get.find<NetworkManager>().checkConnection();
  }
}
