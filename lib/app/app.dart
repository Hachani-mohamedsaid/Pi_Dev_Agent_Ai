import 'package:flutter/material.dart';

import '../presentation/pages/counter_page.dart';
import '../injection_container.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pi_dev_agentia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: CounterPage(
        title: 'Counter (Clean Architecture)',
        controller: InjectionContainer.instance.buildCounterController(),
      ),
    );
  }
}


