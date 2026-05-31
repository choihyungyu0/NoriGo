import {
  buildKeywordSearchPlan,
  selectRoute,
} from "./index.ts";
import type { ItineraryRequest, KtoCandidate } from "./index.ts";

Deno.test("keyword plan expands user interests into Korean searches", () => {
  const searches = buildKeywordSearchPlan(
    request("Myeongdong, Seoul", "Palace, Hanok village, Traditional market"),
  );
  const keywords = searches.map((search) => search.keyword);

  assert(keywords.includes("경복궁"));
  assert(keywords.includes("북촌한옥마을"));
  assert(keywords.includes("광장시장"));
  assert(keywords.includes("명동"));
});

Deno.test("different preference sets select different five-stop routes", () => {
  const cases = [
    request("Myeongdong, Seoul", "Palace, Hanok village, Traditional market"),
    request("Hongdae, Seoul", "Shopping, K-pop, Cafe"),
    request("Seoul Station, Seoul", "Nature, Museum, Quiet", "Solo", "Quiet"),
    request("Jongno, Seoul", "Local food, Traditional market"),
    request("Gangnam, Seoul", "Night view, Couple", "Couple", "Moderate"),
  ];

  const signatures = cases.map((item) => {
    const route = selectRoute(candidatePool, item);
    assertEquals(route.length, 5);
    assertEquals(new Set(route.map((candidate) => candidate.contentid)).size, 5);
    return route.map((candidate) => candidate.contentid).join("|");
  });

  assert(new Set(signatures).size > 1, "routes should vary by preference input");
});

function request(
  baseLocation: string,
  interests: string,
  companionType = "Solo",
  crowdPreference = "Quiet to Moderate",
): ItineraryRequest {
  return {
    user_language: "English",
    trip_days: "1",
    base_location: baseLocation,
    travel_date: "May 18, Sun",
    interests,
    companion_type: companionType,
    crowd_preference: crowdPreference,
  };
}

const candidatePool: KtoCandidate[] = [
  candidate("경복궁", "1001", "12", "서울 종로구 사직로", "Palace", 126.977, 37.579),
  candidate("창덕궁", "1002", "12", "서울 종로구 율곡로", "Palace", 126.991, 37.579),
  candidate("북촌한옥마을", "2001", "12", "서울 종로구 계동길", "Hanok village", 126.984, 37.582),
  candidate("익선동 한옥거리", "2002", "12", "서울 종로구 수표로", "Hanok village", 126.99, 37.573),
  candidate("광장시장", "3001", "38", "서울 종로구 창경궁로", "Traditional market", 127.001, 37.57),
  candidate("망원시장", "3002", "38", "서울 마포구 포은로", "Traditional market", 126.906, 37.556),
  candidate("성수 카페거리", "4001", "39", "서울 성동구 성수이로", "Cafe", 127.054, 37.543),
  candidate("연남동 카페", "4002", "39", "서울 마포구 동교로", "Cafe", 126.923, 37.562),
  candidate("홍대거리", "5001", "12", "서울 마포구 홍익로", "K-pop", 126.923, 37.557),
  candidate("명동거리", "6001", "38", "서울 중구 명동길", "Shopping", 126.985, 37.563),
  candidate("더현대 서울", "6002", "38", "서울 영등포구 여의대로", "Shopping", 126.929, 37.526),
  candidate("국립중앙박물관", "7001", "14", "서울 용산구 서빙고로", "Museum", 126.98, 37.523),
  candidate("서울역사박물관", "7002", "14", "서울 종로구 새문안로", "Museum", 126.971, 37.57),
  candidate("서울숲", "8001", "12", "서울 성동구 뚝섬로", "Nature", 127.037, 37.544),
  candidate("한강공원", "8002", "12", "서울 영등포구 여의동로", "Nature", 126.934, 37.528),
  candidate("남산서울타워", "9001", "12", "서울 용산구 남산공원길", "Night view", 126.988, 37.551),
  candidate("반포한강공원", "9002", "12", "서울 서초구 신반포로", "Couple", 126.995, 37.51),
  candidate("을지로 노포거리", "9101", "39", "서울 중구 을지로", "Local food", 126.991, 37.566),
  candidate("종로 맛집거리", "9102", "39", "서울 종로구 종로", "Local food", 126.991, 37.571),
];

function candidate(
  title: string,
  contentid: string,
  contenttypeid: string,
  addr1: string,
  interest: string,
  mapx: number,
  mapy: number,
): KtoCandidate {
  return {
    title,
    contentid,
    contenttypeid,
    addr1,
    firstimage: "https://example.com/image.jpg",
    mapx,
    mapy,
    matched_interest: interest,
    matched_interests: [interest],
    matched_keywords: [title],
    candidate_score: 0,
    category: interest.toLowerCase().replaceAll(" ", "_"),
    area_key: addr1.split(" ").slice(0, 2).join(" "),
  };
}

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message?: string): void {
  if (actual !== expected) {
    throw new Error(message ?? `expected ${expected}, got ${actual}`);
  }
}
