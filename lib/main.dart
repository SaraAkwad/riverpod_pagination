import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(title),
          ),
          AppPaginationSliverList<String>(
            limit: 10,
            pageValue: (page) => ref.watch(postsProvider(page: page)),
            itemBuilder: (value) => ListTile(title: Text(value)),
          )
        ],
      ),
    );
  }
}

//Fake pagination list

@riverpod
FutureOr<Pagination<String>> posts(PostsRef ref, {int page = 1}) {
  return Future.delayed(
    const Duration(seconds: 2),
    () {
      if (page > 2) return Pagination<String>(data: ['a', 'b'], totalItems: 32);
      return Pagination<String>(
          data: List.generate(10, (index) => 'Post $page $index'),
          totalItems: 32);
    },
  );
}

class Pagination<T> {
  Pagination({required this.data, required this.totalItems});
  final List<T> data;
  final int totalItems;
}

abstract class AppPagination<T> extends StatelessWidget {
  const AppPagination({
    Key? key,
    required this.limit,
    required this.pageValue,
    required this.itemBuilder,
  }) : super(key: key);

  final int limit;
  final AsyncValue<Pagination<T>> Function(int page) pageValue;
  final Widget Function(T value) itemBuilder;

  Widget buildList(
    BuildContext context,
    int? itemCount,
    Widget? Function(BuildContext context, int index) itemBuilder,
  );

  @override
  Widget build(BuildContext context) {
    return buildList(
      context,
      null,
      (context, index) {
        final page = index ~/ limit;
        final itemIndex = index % limit;
        return pageValue(page).when(
          data: (value) {
            if (itemIndex >= value.data.length) {
              return null;
            }
            return itemBuilder(value.data[itemIndex]);
          },
          loading: () {
            if (itemIndex != 0) {
              return null;
            }
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          },
          error: (error, stackTrace) => Center(
            child: Text('Error $error'),
          ),
        );
      },
    );
  }
}

class AppPaginationList<T> extends AppPagination<T> {
  const AppPaginationList({
    Key? key,
    required int limit,
    required AsyncValue<Pagination<T>> Function(int page) pageValue,
    required Widget Function(T value) itemBuilder,
  }) : super(
          key: key,
          limit: limit,
          pageValue: pageValue,
          itemBuilder: itemBuilder,
        );

  @override
  Widget buildList(
    BuildContext context,
    int? itemCount,
    Widget? Function(BuildContext context, int index) itemBuilder,
  ) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class AppPaginationSliverList<T> extends AppPagination<T> {
  const AppPaginationSliverList({
    Key? key,
    required int limit,
    required AsyncValue<Pagination<T>> Function(int page) pageValue,
    required Widget Function(T value) itemBuilder,
  }) : super(
          key: key,
          limit: limit,
          pageValue: pageValue,
          itemBuilder: itemBuilder,
        );

  @override
  Widget buildList(
    BuildContext context,
    int? itemCount,
    Widget? Function(BuildContext context, int index) itemBuilder,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
      ),
    );
  }
}
