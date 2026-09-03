import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/my_quote/data/submission_repository.dart';
import 'package:malssi/features/my_quote/providers/write_providers.dart';

const _availableTags = ['위로', '도전', '사랑', '성장', '협력', '관계', '인내', '자존감', '가족'];

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _textController = TextEditingController();
  final _authorController = TextEditingController();
  final Set<String> _selectedTags = {'위로'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WriteProvider>().load();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<WriteProvider>().submit(
          text: _textController.text,
          author: _authorController.text,
          category: _selectedTags.isEmpty ? '기타' : _selectedTags.first,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '심사 요청이 접수되었습니다.' : '문장을 입력해주세요.'),
      ),
    );
    if (ok) {
      _textController.clear();
      _authorController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final write = context.watch<WriteProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('내 명언 쓰기'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('문장',
                style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            const SizedBox(height: 7),
            TextField(
              controller: _textController,
              maxLines: 3,
              maxLength: 80,
              style: AppTheme.quoteTextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: '마음에 새기고 싶은 문장을 적어주세요',
                hintStyle: TextStyle(fontFamily: null),
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_textController.text.length} / 80',
                style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
              ),
            ),
            const SizedBox(height: 16),
            const Text('출처 · 작성자',
                style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            const SizedBox(height: 7),
            TextField(
              controller: _authorController,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.paper),
              decoration: const InputDecoration(
                hintText: '예) 본인, 책 제목, 인물명',
              ),
            ),
            const SizedBox(height: 16),
            const Text('태그 (최대 3개)',
                style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in _availableTags)
                  ChoiceChip(
                    label: Text('#$tag'),
                    selected: _selectedTags.contains(tag),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedTags.length < 3) {
                            _selectedTags.add(tag);
                          }
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: write.isSubmitting ? null : _submit,
              child: Text(write.isSubmitting ? '접수 중...' : '심사 요청하기'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.ink850,
                border: Border.all(color: AppTheme.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '제출한 명언은 관리자 검수 후 명언 DB에 등록되며, 결과는 마이페이지에서 확인할 수 있어요. 보통 1~2일 소요돼요.',
                style: TextStyle(fontSize: 11.5, height: 1.5, color: AppTheme.muted),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 22, bottom: 4),
              child: Text('내가 제출한 명언',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.paper,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            for (final s in write.mine) _StatusRow(submission: s),
          ],
        ),
      ),
      bottomNavigationBar: const MvpBottomNav(currentIndex: 2),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text('"${submission.text}"',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppTheme.paper,
                )),
          ),
          const SizedBox(width: 12),
          _StatusPill(status: submission.status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final SubmissionStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (status) {
      case SubmissionStatus.pending:
        bg = const Color(0xFF3A3420);
        fg = AppTheme.gold;
      case SubmissionStatus.approved:
        bg = const Color(0xFF233A2C);
        fg = AppTheme.sage;
      case SubmissionStatus.rejected:
        bg = const Color(0xFF3A2323);
        fg = const Color(0xFFC97878);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
