import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/constants.dart';
import '../utils/routes.dart';

class AnimeDrawer extends StatelessWidget {
  const AnimeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * .82,
      backgroundColor: tkDarkerBlue,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tkGradientBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'TakoPlay',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.7,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_rounded, color: tkMutedText),
                  ),
                ],
              ),
            ),
            Container(
              height: 168,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF25365A), Color(0xFF121A2C)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The original square image was heavily cropped in this
                  // wide banner. The transparent character art keeps the
                  // entire subject in frame and leaves room for the copy.
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Image.asset(
                        'assets/images/rem_show.png',
                        height: 156,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xB5090A12), Colors.transparent],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    right: 132,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your anime space',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        SizedBox(height: 3),
                        Text('Browse, save, and keep watching.',
                            style: TextStyle(color: tkMutedText, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('EXPLORE',
                    style: TextStyle(
                      color: tkMutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    )),
              ),
            ),
            _DrawerItem(
              icon: Icons.category_outlined,
              label: 'Genres',
              onTap: () => Get.toNamed(Routes.genreSelectionScreen),
            ),
            _DrawerItem(
              icon: Icons.tune_rounded,
              label: 'Settings',
              onTap: () => Get.toNamed(Routes.settingsScreen),
            ),
            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'About TakoPlay',
              onTap: () => Get.toNamed(Routes.aboutAppScreen),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('TAKOPLAY  •  v1.6.3',
                  style: TextStyle(
                      color: tkMutedText, fontSize: 10, letterSpacing: .8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: tkCoral, size: 21),
                const SizedBox(width: 15),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: tkMutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
