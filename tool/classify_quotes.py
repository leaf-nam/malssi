#!/usr/bin/env python3
"""위키인용집 명언 719件을 7테마로 분류해 앱용 quotes.json을 만든다 (#123).

- 입력: assets/docs/wikiquote.json (원본, 직접 수정 금지)
- 출력: assets/docs/quotes.json [{id, text, author, theme}]
- 방식: 테마 키워드 스코어링(다수결) + 명시 override. 결정적(deterministic).
- 사용법: python3 tool/classify_quotes.py [--report-only]
"""
import json
import sys
from collections import Counter

SRC = 'assets/docs/wikiquote.json'
DST = 'assets/docs/quotes.json'

THEMES = [
    'vitality', 'happiness', 'growth', 'health',
    'peace', 'relationship', 'wisdom',
]

KEYWORDS = {
    'vitality': [
        '용기', '도전', '열정', '의지', '전진', '돌진', '싸우', '승리', '이기',
        '행동', '실천', '결단', '결심', '포기하지', '굴하지', '두려워 마',
        '두려움 없이', '담대', '대담', '정면', '싸움', '투쟁', '정복', '극복',
        '일어나', '뛰어', '달려', '불꽃', '불타', '피가 끓', '가슴이 뛴',
        '독립', '항쟁', '항거', '저항', '결사항전', '돌격', '돌진',
        '물러서지', '꺾이지', '굽히지',
    ],
    'happiness': [
        '행복', '기쁨', '기뻐', '웃음', '웃는', '미소', '즐거', '즐겁',
        '축복', '감사', '희망', '밝은', '밝게', '환희', '황홀',
        '만족', '충만', '복되', '경사', '잔치',
        # '복이' 제외: '보복'·'극복' 오적중 (#123)
    ],
    'growth': [
        '성장', '노력', '배우', '연습', '훈련', '발전', '발달', '성공',
        '꿈', '목표', '미래', '한 걸음', '끈기', '인내', '꾸준', '성취',
        '향상', '진보', '도약', '시작이 반', '천 리', '한 걸음부터',
        '계단', '오르', '등반', '정상', '마라톤', '습관',
        '시간', '근면', '부지런', '게으', '노동', '직업', '사업', '돈',
        '재산', '가난', '부자', '경제', '검소', '절약', '낭비', '성실',
        '새벽', '공부', '시험', '학교', '교육', '스승',
    ],
    'health': [
        '건강', '몸', '병', '아프', '쉼', '휴식', '쉬', '생명', '숨',
        '운동', '걷', '잠', '수면', '피로', '회복', '치료', '의사',
        '장수', '활력소',
    ],
    'peace': [
        '평화', '평온', '고요', '마음의 평화', '침착', '차분', '온화',
        '겸손', '겸허', '용서', '자비', '명상', '침묵', '고독', '여유',
        '느림', '천천히', '숨을 고르', '번뇌', '욕심', '집착', '비움',
        ' 내려놓', '놓아', '고요히',
    ],
    'relationship': [
        '함께', '친구', '우정', '사랑', '가족', '부모', '자식', '형제',
        '이웃', '동료', '나눔', '베풀', '도와', '도움', '신뢰', '믿음',
        '만남', '인연', '동행', '협력', '화합', '배려', '존중', '경청',
        '위로', '격려', '손을 잡', '어깨', '이해', '용납', '화해',
        '사람은', '사람이', '타인', '남을',
    ],
    'wisdom': [
        '지혜', '진리', '깨달', '철학', '사상', '사색', '성찰', '통찰',
        '어리석', '무지', '무식', '우매', '현명', '현자', ' 현인',
        '배움', '가르침', '교훈', '경험', '역사', '고전', '책', '독서',
        '말은', '말을', '언어', '침묵은', '안다는', '아는 것이',
        '모른다는', '질문', '답', '이성', '판단', '분별', '진실',
        '거짓', '참', '옳고 그름', '선악',
        '나라', '민족', '정의', '자유', '평등', '권리', '정치', '사회',
        '정부', '법', '제도', '개혁', '민주', '주권', '식민', '침략',
        '독재', '혁명', '언론', '주의', '이념', '시대', '문명', '국가',
        '국민', '인민', '백성', '통치', '권력', '부패', '부정', '불의',
        '옳지', '그르', '잘못된', '비판', '항의', '투표', '선거', '의회',
        '여성', '여자', '남녀', '성별', '차별', '인권',
    ],
}

# 동점·예외 확정 (dedup_key prefix -> theme). 비워 두면 1순위 테마로 귀속.
# 2026-09-06 키워드 미매칭 147件 직접 판독 (#123).
OVERRIDES = {
    # 서경덕·최영·강경애·강은교
    'f149313bd800': 'wisdom',
    '0922bfcf6568': 'wisdom',
    '27ce2d17c15a': 'wisdom',
    '44196273233b': 'peace',
    'ae6f0f9d457c': 'peace',
    # 카이사르
    'd13c14f23356': 'vitality',
    '3eeb4e7c6335': 'vitality',
    'f5f863f5ebbb': 'wisdom',
    # 이광수
    '418c71998065': 'wisdom',
    '93a26501bc59': 'wisdom',
    '460deebd8f24': 'wisdom',
    'c6e26e709f24': 'vitality',
    '7f5e8fdff5ce': 'wisdom',
    'cf099c985015': 'peace',
    '1131761f64bb': 'peace',
    '7ed3a28e39d8': 'wisdom',
    '8a421e4fb338': 'wisdom',
    'cef913de7c39': 'peace',
    '8f9cfbdf58d0': 'relationship',
    '2b1fafcfa10b': 'happiness',
    '75db366c53a1': 'peace',
    'd3bf34e8d38a': 'peace',
    '5e3fa447d132': 'wisdom',
    '534832d80b0f': 'relationship',
    '991a262a66d8': 'wisdom',
    'c5dbb56e4f5c': 'wisdom',
    'ae256f74c737': 'peace',
    # 허목·황지우
    '728a662ef631': 'wisdom',
    '2f7d11d93e72': 'wisdom',
    '4f2f71a08255': 'wisdom',
    '5fb056c4a67d': 'peace',
    # 노자·맹자·소크라테스·아리스토텔레스·아우렐리우스·장자
    '5225916bf66e': 'relationship',
    '3df18cf37bc0': 'wisdom',
    '867427e2a727': 'wisdom',
    '2f874e8fc550': 'wisdom',
    '694b7e1f499a': 'wisdom',
    'cd6713cfcbf9': 'wisdom',
    'bcfcce53aa97': 'vitality',
    'f3b799826b6f': 'relationship',
    '0e8e9292ada4': 'peace',
    'b222f67feb95': 'peace',
    '7bd270638660': 'wisdom',
    # 정약용·포퍼·키르케고르·김진왕·베이컨
    '526882687bcf': 'wisdom',
    '436875b1f11d': 'wisdom',
    '1801bc1758ce': 'wisdom',
    'fa7153fa2502': 'wisdom',
    'bc1a4aa6ad6a': 'health',
    'f267f11b9b16': 'wisdom',
    # 나폴레옹
    '229634780c20': 'growth',
    'f74b0a85f0a6': 'vitality',
    '2cd724204935': 'vitality',
    'ba5dc27435ee': 'wisdom',
    'cc4de8d4f6cd': 'wisdom',
    '40f8603a1156': 'wisdom',
    'ca30e8f9f554': 'wisdom',
    '7ed94629cb05': 'growth',
    '21e23433b335': 'vitality',
    '503e7dce66e6': 'health',
    '7ff9c65c18f7': 'wisdom',
    # 알프 아르슬란·나혜석
    '8dbeedfb36fc': 'relationship',
    '7c3469418bd1': 'wisdom',
    '357f574ca363': 'wisdom',
    '20e408e6c938': 'wisdom',
    '7124fc0492b0': 'relationship',
    'dc9801fea9ae': 'wisdom',
    '26c8cd88f219': 'wisdom',
    '4dd8fa936d4f': 'vitality',
    # 박중양
    'abe25b1f67c9': 'vitality',
    'd741c146718a': 'wisdom',
    'f888d1ddd6b9': 'wisdom',
    '0aee9e1934f0': 'wisdom',
    '44d320251ebf': 'wisdom',
    'e37f507aef5b': 'wisdom',
    '53534ed68507': 'wisdom',
    '1402a2ed64be': 'wisdom',
    'fd12bf6a7c52': 'wisdom',
    '928d9e0678fd': 'wisdom',
    # 서재필·안창호·유길준·윤치호
    '04bd950be929': 'vitality',
    '7bb1e0dc0d79': 'wisdom',
    '9a27ed6370e5': 'wisdom',
    '83f811a77b60': 'wisdom',
    '68576a728595': 'wisdom',
    'aa046430ccad': 'wisdom',
    '4daea1204882': 'wisdom',
    'e6cd369356e1': 'wisdom',
    'e0a643c8a648': 'wisdom',
    '41cf9a60863e': 'relationship',
    '9a2654651f5a': 'wisdom',
    'db78c7dbc5f8': 'relationship',
    # 이회영·허정숙·러셀·니체·트로츠키
    '182b45802831': 'vitality',
    'f9b806c8bda4': 'wisdom',
    'fde2c9167573': 'growth',
    'd2aa28aefb2b': 'vitality',
    'f7f535c1c0e4': 'wisdom',
    'b71a6d748df4': 'wisdom',
    'ae3d270f9341': 'wisdom',
    '62cad2dabc03': 'wisdom',
    'ccca825f4bc0': 'wisdom',
    # 게이츠·다윈·케인스·크루그먼·가지타
    '136bcfb1b33b': 'growth',
    'e25e35dccc61': 'growth',
    '7a4a31583ee3': 'wisdom',
    'de8dacb6c8d9': 'wisdom',
    '324aab681e9f': 'wisdom',
    '67a383a1f9cc': 'wisdom',
    '519b3e9a7010': 'wisdom',
    'ca56406c667f': 'wisdom',
    '521b54078958': 'growth',
    # 뉴턴·아인슈타인·유카와
    '35ee1f5384b1': 'growth',
    '5c276688d9ef': 'wisdom',
    'd28756c1c28b': 'growth',
    '797afcd3798a': 'wisdom',
    '8ada0cc67c46': 'wisdom',
    'acd4e742f914': 'wisdom',
    'a121d3fff4e2': 'wisdom',
    'f32e22b616dc': 'peace',
    # 프랭클린
    'd7f08d3104f7': 'growth',
    'c7cb20057b65': 'wisdom',
    '6b5c05e0fe9d': 'wisdom',
    '78e236dfb079': 'growth',
    '27b1dfd6f0e6': 'growth',
    '05fba86d2d91': 'wisdom',
    'a0ac12abfd8c': 'wisdom',
    # 기든스·라플라스·오일러·스피노자
    'f8b2957aad75': 'wisdom',
    '7e38584a7279': 'wisdom',
    'dcb4e0e50ec7': 'wisdom',
    'be6162d49588': 'peace',
    '0068ddd3a229': 'happiness',
    'dda4519385a6': 'wisdom',
    '986017b01e6c': 'vitality',
    'd8580fd511d5': 'wisdom',
    # 케플러·야마나카·파스퇴르·혼조·에디슨·강원택·세이건·곽재식·노요리
    'a28412105d36': 'wisdom',
    '24886fe42c01': 'wisdom',
    '89b78a3709b9': 'peace',
    '6436a3aa12c9': 'growth',
    '5e5a5476740b': 'growth',
    '54324b359e82': 'growth',
    '02a5b5889ad1': 'growth',
    '8ec141c4f597': 'wisdom',
    'd7dbe47a4336': 'vitality',
    'fc44c9e9e5ea': 'wisdom',
    '1a82502b9227': 'wisdom',
    '0013fab48217': 'growth',
    'e1b0dd7569be': 'growth',
    'c6fedd59bde3': 'wisdom',
    '9263d47e8fdb': 'wisdom',
    'c1144c1d1957': 'wisdom',
    '70bdea7ce4c6': 'happiness',
    '25b58fca3f13': 'wisdom',
}

PRIORITY = [
    'health', 'relationship', 'happiness', 'peace',
    'growth', 'vitality', 'wisdom',
]


def classify(text):
    scores = Counter()
    for theme, words in KEYWORDS.items():
        for w in words:
            if w in text:
                scores[theme] += 1
    if not scores:
        return None, {}
    best = max(scores.values())
    tied = [t for t, s in scores.items() if s == best]
    if len(tied) == 1:
        return tied[0], dict(scores)
    for p in PRIORITY:
        if p in tied:
            return p, dict(scores)
    return tied[0], dict(scores)


def main():
    report_only = '--report-only' in sys.argv
    with open(SRC, encoding='utf-8') as f:
        data = json.load(f)
    out = []
    unmatched = []
    tied_total = 0
    dist = Counter()
    for d in data:
        key = d['dedup_key']
        text = d['quote']
        theme = OVERRIDES.get(key[:12])
        scores = {}
        if theme is None:
            theme, scores = classify(text)
            if theme is None:
                unmatched.append((key[:12], text, d.get('author', '')))
                continue
            if len([t for t, s in scores.items() if s == max(scores.values())]) > 1:
                tied_total += 1
        dist[theme] += 1
        out.append({
            'id': key,
            'text': text,
            'author': d.get('author', ''),
            'theme': theme,
        })
    print(f'total={len(data)} classified={len(out)} unmatched={len(unmatched)} tied={tied_total}')
    print('dist:', dict(dist))
    if unmatched:
        print(f'--- unmatched samples (max 15) ---')
        for k, t, a in unmatched[:15]:
            print(f'[{k}] {t} — {a}')
    if report_only:
        return
    with open(DST, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(f'wrote {DST} ({len(out)} entries)')


if __name__ == '__main__':
    main()
