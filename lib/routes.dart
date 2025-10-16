import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/community_page.dart';
import 'pages/detect_page.dart';


class Routes {
static const home = '/';
static const community = '/community';
static const detect = '/detect';


static Map<String, WidgetBuilder> getRoutes() {
return {
home: (_) => const HomePage(),
community: (_) => const CommunityPage(),
detect: (_) => const DetectPage(),
};
}
}