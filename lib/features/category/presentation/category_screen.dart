import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/category/data/hashtag_repository.dart';
import 'package:malssi/features/category/providers/category_providers.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('카테고리')),
      body: category.isLoading && category.tags.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.ink800,
                      border: Border.all(color: AppTheme.line),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('#해시태그로 명언 찾아보기',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: category.topTags.length,
                      itemBuilder: (context, index) =>
                          _CatCell(tag: category.topTags[index]),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text('태그 전체',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.muted)),
                  ),
                  for (final tag in category.tags) _CatRow(tag: tag),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: const MvpBottomNav(currentIndex: 1),
    );
  }
}

class _CatCell extends StatelessWidget {
  const _CatCell({required this.tag});

  final HashtagCount tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ink800,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('#${tag.name}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.sage,
              )),
          const SizedBox(height: 6),
          Text('${tag.count}개',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
        ],
      ),
    );
  }
}

class _CatRow extends StatelessWidget {
  const _CatRow({required this.tag});

  final HashtagCount tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.ink850,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('#${tag.name}',
              style: const TextStyle(fontSize: 13, color: AppTheme.paper)),
          Text('${tag.count}개',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
        ],
      ),
    );
  }
}
