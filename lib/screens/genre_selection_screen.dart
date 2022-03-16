import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/anime.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/tako_animation.dart';
import '../widgets/tako_scaffold.dart';

class GenreSelectionScreen extends StatefulWidget {
  const GenreSelectionScreen({Key? key}) : super(key: key);

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: takoAnimationDuration));
    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TakoScaffoldWithBackButton(
      appBarTitle: 'Genres',
      body: ListView.builder(
          shrinkWrap: true,
          itemCount: genreList.length,
          itemBuilder: (context, index) {
            controller.forward();
            return AnimatedBuilder(
              animation: controller,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(genreList[index].name),
                  onTap: () {
                    Get.toNamed(Routes.genreScreen,
                        arguments: genreList[index]);
                  },
                ),
              ),
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.translationValues(
                      0,
                      100 *
                          (1.0 -
                              TakoCurveAnimation(
                                      controller, index, genreList.length)
                                  .value),
                      0),
                  child: child,
                );
              },
            );
          }),
    );
  }
}
