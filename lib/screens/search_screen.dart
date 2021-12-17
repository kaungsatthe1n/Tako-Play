import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../theme/tako_theme.dart';
import '../utils/routes.dart';
import '../models/anime.dart';
import '../services/anime_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool hasValue = false;
  String value = '';
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final itemHeight = 42.h;
    final itemWidth = 100.w / 2;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: _formKey,
          controller: _controller,
          decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white,
                ),
                onPressed: () {
                  _controller.clear();
                },
              ),
              hintText: 'Search...',
              border: InputBorder.none),
          onSubmitted: (val) {
            setState(() {
              hasValue = true;
            });
            value = val;
          },
        ),
      ),
      body: hasValue
          ? FutureBuilder<AnimeResults>(
              future: AnimeService().getSearchResult(value),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'An error occured',
                      style: TakoTheme.darkTextTheme.headline3,
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done) {
                  final list = snapshot.data!.animeList;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: (itemWidth / itemHeight),
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: list!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          Get.toNamed(
                            Routes.videoListScreen,
                            arguments: {'anime': list[index]},
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  width: itemWidth.toDouble(),
                                  height: 24.h,
                                  fit: BoxFit.cover,
                                  imageUrl: list[index].imageUrl.toString(),
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  list[index].name.toString(),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: TakoTheme.darkTextTheme.bodyText1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              })
          : Container(),
    );
  }
}
