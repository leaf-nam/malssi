import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routing/app_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_routerObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_routerObserver);
    super.dispose();
  }

  final GoRouterObserver _routerObserver = GoRouterObserver();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services will be added here
      ],
      child: MaterialApp.router(
        routerDelegate: appRouter.routerDelegate,
        routeInformationProvider: appRouter.routeInformationProvider,
        routeInformationParser: appRouter.routeInformationParser,
        routeDelegate: appRouter.routeDelegate,
        // supportedLocales: [...],
        // localeListBoxEnabled: true,
      ),
    );
  }
}