import 'package:go_router/go_router.dart';
import '../../features/home/presentation/main_page.dart';
import '../../features/models/presentation/models_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/models',
      name: 'models',
      builder: (context, state) => const ModelsPage(),
    ),
  ],
);
