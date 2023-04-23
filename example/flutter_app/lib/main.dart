import 'package:flutter/material.dart';
import 'package:hors/hors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  initializeDateFormatting('ru');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hors demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.lightBlue.shade50,
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: HorsProvider(
        hors: Hors(
          recognizers: Recognizer.all,
          tokenParsers: TokenParsers.all,
        ),
        child: const Page(),
      ),
    );
  }
}

class HorsProvider extends InheritedWidget {
  final Hors hors;

  const HorsProvider({
    super.key,
    required this.hors,
    required super.child,
  });

  @override
  bool updateShouldNotify(HorsProvider oldWidget) => false;

  static Hors of(BuildContext context) {
    final HorsProvider? provider =
        context.dependOnInheritedWidgetOfExactType<HorsProvider>();
    return provider!.hors;
  }
}

class Page extends StatelessWidget {
  const Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        bottom: false,
        child: Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final _controller = TextEditingController();
  HorsResult? _result;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            children: [
              if (_result != null)
                Card(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Текст без дат',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!.textWithoutTokens.isNotEmpty
                            ? _result!.textWithoutTokens
                            : '–',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              if (_result != null)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _result!.tokens.length,
                  itemBuilder: (context, i) => DateTimeTokenCard(
                    token: _result!.tokens[i],
                  ),
                ),
            ],
          ),
        ),
        Input(controller: _controller),
      ],
    );
  }

  void _onTextChanged() {
    setState(() {});
    _result = HorsProvider.of(context).parse(_controller.text);
  }
}

class Input extends StatelessWidget {
  final TextEditingController controller;

  const Input({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Material(
      color: theme.colorScheme.surfaceVariant,
      elevation: 10,
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
          top: 8,
          right: 8,
          bottom: 8 + mediaQuery.padding.bottom,
        ),
        child: TextField(
          autofocus: true,
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            isDense: true,
            hintText: 'Введите событие',
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(100),
            ),
            fillColor: theme.colorScheme.background,
            filled: true,
            suffixIcon: controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: () {
                      controller.text = '';
                    },
                    icon: const Icon(Icons.clear),
                  ),
          ),
        ),
      ),
    );
  }
}

class DateTimeTokenCard extends StatelessWidget {
  final DateTimeToken token;

  const DateTimeTokenCard({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dateFormatter = DateFormat.yMMMMd('ru');
    final timeFormatter = DateFormat.Hm('ru');

    final String title;
    switch (token.type) {
      case DateTimeTokenType.fixed:
        title = 'Дата';
        break;
      case DateTimeTokenType.period:
        title = 'Период';
        break;
      case DateTimeTokenType.spanForward:
      case DateTimeTokenType.spanBackward:
        title = 'Относительная дата';
        break;
    }

    String dateValue;
    dateValue = dateFormatter.format(token.date);
    if (token.hasTime) {
      dateValue += ' ';
      dateValue += timeFormatter.format(token.date);
    }

    String? dateToValue;
    if (token.type == DateTimeTokenType.period && token.dateTo != null) {
      dateToValue = dateFormatter.format(token.dateTo!);
      if (token.hasTime) {
        dateToValue += ' ';
        dateToValue += timeFormatter.format(token.dateTo!);
      }
    }

    String? spanValue;
    if ((token.type == DateTimeTokenType.spanForward ||
            token.type == DateTimeTokenType.spanBackward) &&
        token.span != null) {
      spanValue = token.span!.toString();
    }

    return Card(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            dateValue,
            style: theme.textTheme.titleLarge,
          ),
          if (dateToValue != null) ...[
            const SizedBox(height: 4),
            Text(
              '–',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              dateToValue,
              style: theme.textTheme.titleLarge,
            ),
          ],
          if (spanValue != null) ...[
            const SizedBox(height: 8),
            Text(
              spanValue,
              style: theme.textTheme.titleLarge,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
