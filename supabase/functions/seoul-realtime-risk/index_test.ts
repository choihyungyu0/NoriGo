import {
  buildRiskResponse,
  crowdScoreFor,
  incidentBonusFromRecord,
  resolveSeoulArea,
  riskLevelFor,
  triggerTypeFor,
} from "./index.ts";
import type { SeoulRealtimeArea } from "./index.ts";

Deno.test("alias matching maps Bukchon Hanok Village to Korean AREA_NM", () => {
  const resolved = resolveSeoulArea({
    scheduled_place_name: "Bukchon Hanok Village",
  }, areas);

  assert(resolved);
  assertEquals(resolved.area.area_nm, "북촌한옥마을");
  assertEquals(resolved.match_type, "exact_alias");
});

Deno.test("unmatched area returns no resolved AREA_NM", () => {
  const resolved = resolveSeoulArea({
    scheduled_place_name: "Imaginary Museum",
  }, areas);

  assertEquals(resolved, null);
});

Deno.test("congestion levels map to crowd scores", () => {
  assertEquals(crowdScoreFor("여유"), 20);
  assertEquals(crowdScoreFor("보통"), 45);
  assertEquals(crowdScoreFor("약간 붐빔"), 70);
  assertEquals(crowdScoreFor("붐빔"), 85);
});

Deno.test("incident bonus is capped at 15", () => {
  const incident = incidentBonusFromRecord({
    ACDNT_CN: "traffic control near exit",
    EVENT_STTS: "large event",
  });

  assertEquals(incident.checked, true);
  assertEquals(incident.bonus, 15);
});

Deno.test("risk score is capped at 100", () => {
  const resolved = resolveSeoulArea({
    scheduled_place_name: "Bukchon Hanok Village",
  }, areas);
  assert(resolved);

  const response = buildRiskResponse(
    { scheduled_place_name: "Bukchon Hanok Village" },
    resolved,
    {
      area_nm: "북촌한옥마을",
      congestion_level: "붐빔",
      congestion_message: "Busy.",
      population_min: 1000,
      population_max: 2000,
      population_time: "2026-06-03 14:00",
      raw: {
        AREA_CONGEST_LVL: "붐빔",
        ACDNT_CN: "control active",
      },
    },
  );

  assertEquals(response.risk_score, 100);
  assertEquals(response.risk_level, "Very High");
});

Deno.test("risk score at or above 85 triggers alert", () => {
  assertEquals(riskLevelFor(85), "Very High");
  assertEquals(triggerTypeFor(85), "crowd_spike");
});

const areas: SeoulRealtimeArea[] = [
  {
    area_nm: "북촌한옥마을",
    aliases: ["Bukchon Hanok Village", "Bukchon", "북촌"],
  },
  {
    area_nm: "경복궁",
    aliases: ["Gyeongbokgung Palace", "Gyeongbokgung", "경복궁"],
  },
];

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message?: string): void {
  if (actual !== expected) {
    throw new Error(message ?? `expected ${expected}, got ${actual}`);
  }
}
