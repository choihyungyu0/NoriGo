# NoriGo

NoriGo는 한국을 방문하는 외국인 관광객을 위한 AI 여행 어시스턴트입니다. 혼잡도, 앱 대기/예약 리스크, 문화 에티켓, 숨은 로컬 장소 추천을 한 흐름으로 연결해 여행자가 더 자연스럽고 덜 붐비는 동선을 선택하도록 돕습니다.

현재 앱은 Flutter 모바일 앱을 중심으로 구현되어 있으며, Supabase가 설정되지 않아도 로컬 목 데이터로 주요 화면을 확인할 수 있습니다. Supabase URL과 anon key가 제공되면 Auth, Edge Function, REST 테이블, Storage를 사용해 실제 연동 경로로 전환됩니다.

## 현재 구현 상태

- Flutter 기반 크로스 플랫폼 앱: Android, iOS, Web, Windows, macOS, Linux 프로젝트 구조 포함
- 스플래시, 이메일 로그인/회원가입, 온보딩, 홈, AI 일정, 문화 스캔, 숨은 장소 탐색, 마이페이지 화면 구현
- Supabase Auth REST 로그인과 액세스 토큰 저장/재사용
- Supabase Edge Functions를 통한 ennoia Agent API, KTO OpenAPI, 서울 실시간 도시데이터 연동
- Supabase REST 테이블 기반 일정, 장소 저장, 문화 스캔 기록, Re-Trip 기록, 동의 정보 저장
- 카메라/ML Kit 기반 Culture Scan 흐름과 선택형 수동 보정 UX
- ARB 기반 영어/한국어 로컬라이제이션과 앱 내 언어 변경
- 네트워크, 외부 키, 테이블 권한이 없어도 로컬 fallback으로 앱이 깨지지 않는 mock-first 구조

## 주요 기능

### Auth and Onboarding

- NoriGo 브랜딩 스플래시 후 로그인 화면으로 이동
- 이메일 로그인/회원가입은 Supabase Auth REST API 사용
- 온보딩에서 선호 언어, 여행지, 첫 방문 여부, 목적, 여행 기간, 동행 유형, 음식 요구사항, 대기 도움 필요 여부 수집
- 데이터 동의와 위치 동의를 분리해서 저장
- 위치를 거부하거나 건너뛰어도 기본 지역 기반으로 Discover와 일정 기능 사용 가능

### AI Itinerary

- 온보딩 정보와 관심사를 바탕으로 AI 일정 생성
- `ennoia-itinerary` Edge Function이 KTO OpenAPI 후보지를 조회, 중복 제거, 선호도/거리/다양성/혼잡 선호 기준으로 후보를 점수화
- 선택된 KTO 후보를 `KTO_DATA`로 ennoia에 전달해 추천 이유, 문화 팁, 체류 시간, 혼잡 레벨 설명 생성
- 생성된 일정은 `itinerary_plans`, `itinerary_items` 테이블에 저장 가능
- KTO 또는 ennoia 설정이 없거나 실패하면 mock/fallback 일정으로 계속 동작

### Re-Trip and Crowd Alert

- 일정 저장 또는 일정 확인 중 서울 실시간 혼잡 리스크를 검사
- `seoul-realtime-risk` Edge Function이 서울 OpenAPI `citydata_ppltn` 데이터를 사용해 위험도를 계산
- 혼잡하거나 앱 대기 리스크가 높은 장소는 Crowd Alert로 안내
- `ennoia-retrip` Edge Function이 대체 장소를 추천하고 선택 결과를 일정에 반영
- Re-Trip 이벤트와 선택 대안은 `retrip_events`와 `itinerary_items`에 저장

### Culture Scan Guide

- 카메라 프리뷰 또는 fallback 배경을 통해 현재 장소/상황을 문화 가이드로 연결
- ML Kit 이미지 라벨링과 선택형 custom call bell classifier로 식당 호출벨 등 상황을 감지
- 감지 결과가 불확실하면 사용자가 장소/상황을 수동 선택
- `culture-vision-detect` Edge Function은 서버 측 비전 제공자가 설정된 경우 감지 보조 역할 수행
- `ennoia-culture-guide` Edge Function은 curated culture DB와 ennoia를 사용해 실제 행동 중심의 문화 설명 생성
- 광범위한 정치, 사회 논쟁, 밈, 고정관념 등 여행 행동과 무관한 주제는 제한
- 스캔 기록과 이미지 경로는 Supabase Storage/테이블에 저장 가능

### Discover

- 숨은 로컬 장소, 조용한 카페, 디저트, 로컬 푸드, 포토 스팟, 문화 장소 추천
- `flutter_map`과 OpenStreetMap public tiles를 사용한 개발/데모용 지도
- 위치 권한이 있으면 현재 좌표 기준, 없으면 온보딩 base location과 서울 기본 좌표 기준
- `discover-recommendations` Edge Function이 KTO OpenAPI와 로컬/혼잡 신호를 활용
- 추천 장소 저장은 `saved_places` 테이블을 사용하며, 실패 시 로컬 저장 메시지로 fallback

### My Page

- 로그인 사용자의 프로필, 선호 언어, 관심사, 저장 일정, 저장 장소, 문화 스캔, Re-Trip 기록 요약
- Supabase 테이블 접근이 불가능하거나 일부 테이블이 없으면 local preview로 표시
- 언어 변경은 로컬에 저장되고, Supabase 프로젝트에 `trip_preferences`가 있으면 `preferred_language` 동기화 시도

### Localization

- `lib/l10n/app_en.arb`, `lib/l10n/app_ko.arb` 기반 Flutter localization
- 지원 UI 언어: 영어, 한국어
- AI 생성 콘텐츠는 새 요청 시 선택된 `user_language`를 전달
- 기존 저장 기록은 저장 당시 언어 그대로 표시

## 기술 스택

| 영역 | 사용 기술 |
| --- | --- |
| App | Flutter, Dart SDK `^3.11.5`, Material |
| UI | 커스텀 NoriGo theme, 공통 카드/칩/버튼/하단 내비게이션 위젯 |
| 상태 관리 | `ChangeNotifier` 기반 controller와 repository 인터페이스 |
| 저장소 | `shared_preferences`, platform storage, Supabase REST |
| 인증 | Supabase Auth REST, JWT access token 기반 세션 |
| Backend | Supabase Edge Functions, Supabase REST, Supabase Storage, RLS migrations |
| AI | ennoia Agent API, 프롬프트/응답 validator/harness |
| 공공데이터 | Korea Tourism Organization OpenAPI, Seoul citydata realtime API |
| 지도/위치 | `flutter_map`, `latlong2`, `geolocator`, OpenStreetMap tiles |
| 카메라/비전 | `camera`, `google_mlkit_image_labeling`, custom TFLite labeler asset |
| 네트워크 | `http` |
| 로컬라이제이션 | Flutter ARB, `flutter_localizations`, `intl` |
| 테스트 | Flutter widget/unit tests, Supabase migration tests, Deno Edge Function tests |
| ML 도구 | Python training/validation scripts under `tools/ml/` |

## 프로젝트 구조

```text
lib/
  app/                    # App, router, theme
  core/                   # 공통 위젯, localization, services, auth/location utils
  data/                   # 공통 모델, mock data, repository interfaces
  features/
    auth/                 # 로그인/회원가입
    onboarding/           # 여행 기본 정보, 관심사/알림, 동의
    home/                 # 홈 shell과 하단 탭 진입
    itinerary/            # AI 일정, 저장, Crowd Alert 연결
    crowd/                # 서울 실시간 혼잡 위험도
    culture_scan/         # 카메라, 비전, 문화 가이드
    discover/             # 숨은 장소 추천과 지도
    ennoia/               # ennoia Agent repository/domain
    my/                   # 마이페이지 요약과 기록
supabase/
  functions/              # Edge Functions
  migrations/             # 테이블, Storage, RLS 정책
assets/
  images/                 # 화면별 브랜드/일러스트 이미지
  ml/                     # 앱에 번들되는 TFLite 모델과 label 파일
tools/ml/                 # 호출벨 classifier 학습/검증 스크립트
scripts/                  # Edge Function smoke test 스크립트
test/                     # 앱, feature, Supabase migration 테스트
```

## Supabase 구성

Flutter 앱은 공개 설정만 `--dart-define`으로 받습니다.

```powershell
flutter run `
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="your-supabase-anon-key"
```

Supabase가 설정되지 않은 경우 앱은 mock repository와 local fallback을 사용합니다.

### Edge Functions

```text
supabase/functions/ennoia-culture-guide
supabase/functions/ennoia-itinerary
supabase/functions/ennoia-retrip
supabase/functions/discover-recommendations
supabase/functions/seoul-realtime-risk
supabase/functions/culture-vision-detect
```

배포 예시:

```powershell
npx.cmd supabase functions deploy ennoia-culture-guide
npx.cmd supabase functions deploy ennoia-itinerary
npx.cmd supabase functions deploy ennoia-retrip
npx.cmd supabase functions deploy discover-recommendations
npx.cmd supabase functions deploy seoul-realtime-risk
npx.cmd supabase functions deploy culture-vision-detect
```

### Edge Function secrets

프로덕션 키는 Flutter 앱에 넣지 않고 Supabase secret으로만 관리합니다.

```powershell
npx.cmd supabase secrets set ENNOIA_API_ENDPOINT="https://api.ennoia.so/api/preset/v2/chat/completions"
npx.cmd supabase secrets set ENNOIA_PROJECT="your-ennoia-project"
npx.cmd supabase secrets set ENNOIA_API_KEY="your-ennoia-api-key"
npx.cmd supabase secrets set ENNOIA_CULTURE_HASH="your-culture-agent-hash"
npx.cmd supabase secrets set ENNOIA_ITINERARY_API_HASH="your-itinerary-agent-hash"
npx.cmd supabase secrets set ENNOIA_RETRIP_HASH="your-retrip-agent-hash"
npx.cmd supabase secrets set KTO_SERVICE_KEY="your-kto-openapi-service-key"
npx.cmd supabase secrets set SEOUL_CITYDATA_API_KEY="your-seoul-citydata-key"
npx.cmd supabase secrets set SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
```

선택 secret:

- `ENNOIA_RETRIP_API_HASH`: Re-Trip 전용 hash alias
- `ENNOIA_USER_ID`: ennoia 호출에서 고정 사용자 ID가 필요할 때 사용
- `VISION_PROVIDER_ENDPOINT`, `VISION_PROVIDER_API_KEY`: `culture-vision-detect`에서 외부 비전 제공자를 사용할 때 사용

### 주요 테이블과 Storage

마이그레이션은 `supabase/migrations/`에 있습니다.

- `user_consents`: 데이터/위치 동의 저장
- `itinerary_plans`, `itinerary_items`: 일정 저장과 Re-Trip 변경 반영
- `retrip_events`: 혼잡 경고와 대체 장소 선택 이력
- `culture_guide_entries`: curated 문화 가이드 DB
- `culture_scan_records`: 문화 스캔 기록과 응답 JSON
- `saved_places`: Discover 저장 장소
- `seoul_realtime_areas`: 서울 실시간 데이터 area 매핑
- `culture-scans` Storage bucket: 스캔 이미지 저장 경로

앱은 `trip_preferences` 테이블이 있는 Supabase 프로젝트에서는 선호 언어와 여행 선호 정보를 동기화하려고 시도합니다. 테이블이 없거나 권한이 맞지 않으면 로컬 설정으로 fallback합니다.

## 실행

```powershell
flutter pub get
flutter run
```

Supabase 없이 UI와 fallback 동작만 확인할 때는 `flutter run`만으로 충분합니다.

## 검증

```powershell
dart format .
flutter analyze
flutter test
```

Supabase Edge Function smoke test 예시:

```powershell
$env:SUPABASE_URL="https://your-project.supabase.co"
$env:SUPABASE_ANON_KEY="your-supabase-anon-key"

.\scripts\smoke_itinerary.ps1
.\scripts\smoke_retrip.ps1
.\scripts\smoke_culture_guide.ps1
.\scripts\smoke_culture_vision.ps1
.\scripts\smoke_discover_recommendations.ps1
.\scripts\smoke_seoul_realtime_risk.ps1
```

Edge Function 단위 테스트는 각 함수의 `index_test.ts`를 Deno로 실행합니다.

```powershell
deno test supabase/functions/ennoia-itinerary/index_test.ts
deno test supabase/functions/ennoia-culture-guide/index_test.ts
deno test supabase/functions/culture-vision-detect/index_test.ts
deno test supabase/functions/seoul-realtime-risk/index_test.ts
```

## Custom Call Bell Classifier

Culture Scan의 첫 custom object는 `restaurant_call_bell`입니다. 앱은 ML Kit custom image labeling을 통해 `assets/ml/call_bell_labeler.tflite`와 `assets/ml/call_bell_labels.txt`를 읽습니다.

학습 데이터는 Git에 포함하지 않습니다.

```text
ml_data/call_bell/
  train/
    restaurant_call_bell/
    not_restaurant_call_bell/
  val/
    restaurant_call_bell/
    not_restaurant_call_bell/
  test/
    restaurant_call_bell/
    not_restaurant_call_bell/
```

학습과 검증:

```powershell
python tools/ml/validate_call_bell_dataset.py
python tools/ml/train_call_bell_classifier.py
python tools/ml/check_dataset_not_bundled.py
```

생성물:

```text
build/ml/call_bell_labeler.tflite
build/ml/call_bell_labels.txt
build/ml/call_bell_metrics.json
```

앱에 번들되는 runtime ML 파일은 아래 두 개뿐입니다.

```text
assets/ml/call_bell_labeler.tflite
assets/ml/call_bell_labels.txt
```

신뢰도 기준:

- `>= 0.80`: 호출벨로 감지하고 사용자 확인 요청
- `0.60 - 0.79`: 호출벨일 수 있다고 제안하고 사용자 확인 요청
- `< 0.60` 또는 negative class: 수동 선택으로 이동

현재 한계: 호출벨 모델은 bounding box detection이 아니라 이미지 classification입니다. 호출벨 존재 가능성은 판단하지만 화면의 정확한 위치는 표시하지 않습니다.

## 보안 메모

- 실제 API key, Supabase service role key, 로컬 `.env` 파일은 커밋하지 않습니다.
- Flutter 앱에는 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 같은 공개 설정만 전달합니다.
- KTO, Seoul, ennoia, vision provider key는 Supabase Edge Function secret으로만 관리합니다.
- `ml_data/`는 로컬 학습 데이터이며 Flutter assets나 Git에 포함하지 않습니다.
- OpenStreetMap public tiles는 개발/데모용입니다. 운영 환경에서는 타일 제공자, 캐싱, attribution 정책을 별도로 정해야 합니다.
