#!/usr/bin/env python3
"""속담 1차 스크리닝 (#152 후속, 1.0.3용).

- 입력: /Users/leaf/app/test/proverbs.csv (word, definition, target_code, link)
- 출력: docs/quotes/proverbs_candidates.csv
  (word, definition, theme, score, flags, target_code, link)
- 방식:
  - tool/classify_quotes.py 의 7테마 KEYWORDS 로 스코어링 → 최고 테마 부여.
    매칭 0건이면 theme='none' (어느 타입에도 속하지 않음 → 1차 제외).
  - 성적/폭력 강한 표현은 flags=strong 으로 제외.
    약한 표현은 flags=gray 로 남겨 사람이 판독.
  - word 중복은 최고점 1건만 유지.
- 사용법: python3 tool/classify_proverbs.py
"""
import csv
import sys
from collections import defaultdict

sys.path.insert(0, 'tool')
from classify_quotes import KEYWORDS, THEMES

SRC = '/Users/leaf/app/test/proverbs.csv'
DST = 'docs/quotes/proverbs_candidates.csv'

# 성적 표현: 강한 것(자동 제외) / 약한 것(사람 판독).
SEXUAL_STRONG = [
    '자지', '보지', '좆', '불알', '성교', '성관계', '음란', '자위',
    '색정', '간음', '간통', '색욕', '음탕', '유부녀와', '유부남과',
]
SEXUAL_GRAY = [
    '첩', '기생', '화냥', '정조', '색', '음', '밝히', '계집',
    '사내', '남녀', '남편', '아내', '각시', '신랑', '신부',
    '젖', '가슴', '엉덩이', '치마', '바지', '속곳',
]

# 폭력 표현: 강한 것(자동 제외) / 약한 것(사람 판독).
VIOLENT_STRONG = [
    '목을 베', '목 베', '칼로 찌', '찔러 죽', '때려죽', '패 죽',
    '죽여 버리', '맞아 죽', '피투성이', '피를 흘리', '목숨을 끊',
    '목을 매', '독을 먹', '불에 태워 죽', '산 채로',
]
VIOLENT_GRAY = [
    '죽', '때리', '패', '칼', '창', '활', '총', '피', '매',
    '폭력', '싸움', '전쟁', '살인', '살해',
]


def flags_for(text):
    flags = set()
    for w in SEXUAL_STRONG:
        if w in text:
            flags.add('sexual:strong')
            break
    for w in SEXUAL_GRAY:
        if w in text:
            flags.add('sexual:gray')
            break
    for w in VIOLENT_STRONG:
        if w in text:
            flags.add('violent:strong')
            break
    for w in VIOLENT_GRAY:
        if w in text:
            flags.add('violent:gray')
            break
    return sorted(flags)


def score_theme(text, keywords):
    distinct = sum(1 for kw in keywords if kw in text)
    total = sum(text.count(kw) for kw in keywords if kw in text)
    return distinct, total


def main():
    with open(SRC, encoding='utf-8-sig') as f:
        rows = list(csv.DictReader(f))

    best = {}  # word -> row dict (중복 시 최고점 유지)
    stats = defaultdict(int)
    for r in rows:
        text = f"{r['word']} {r['definition']}"
        scored = {
            t: score_theme(text, KEYWORDS[t]) for t in THEMES
        }
        ranked = sorted(
            scored.items(), key=lambda kv: (kv[1][0], kv[1][1]),
            reverse=True,
        )
        theme, (distinct, total) = ranked[0]
        if distinct == 0:
            theme = 'none'
        flags = flags_for(text)
        stats[f'theme:{theme}'] += 1
        for fl in flags:
            stats[f'flag:{fl}'] += 1

        strong = any(fl.endswith(':strong') for fl in flags)
        if theme == 'none' or strong:
            stats['excluded'] += 1
            continue

        key = (theme, distinct, total)
        prev = best.get(r['word'])
        if prev is None or key > (prev['theme'], prev['d'], prev['t']):
            best[r['word']] = {
                'word': r['word'],
                'definition': r['definition'],
                'theme': theme,
                'd': distinct,
                't': total,
                'flags': '|'.join(flags),
                'target_code': r['target_code'],
                'link': r['link'],
            }

    out = sorted(
        best.values(), key=lambda x: (x['theme'], -x['d'], -x['t']),
    )
    with open(DST, 'w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=[
            'word', 'definition', 'theme', 'score_distinct',
            'score_total', 'flags', 'target_code', 'link',
        ])
        w.writeheader()
        for x in out:
            w.writerow({
                'word': x['word'],
                'definition': x['definition'],
                'theme': x['theme'],
                'score_distinct': x['d'],
                'score_total': x['t'],
                'flags': x['flags'],
                'target_code': x['target_code'],
                'link': x['link'],
            })

    print(f'input rows: {len(rows)}')
    for k in sorted(stats):
        print(f'  {k}: {stats[k]}')
    print(f'candidates: {len(out)} -> {DST}')
    per_theme = defaultdict(int)
    for x in out:
        per_theme[x['theme']] += 1
    for t in THEMES:
        print(f'  {t}: {per_theme[t]}')


if __name__ == '__main__':
    main()
