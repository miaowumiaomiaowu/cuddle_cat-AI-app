# AI Analysis API (FastAPI) Draft

## Endpoints

1) POST /analyze/emotion
- input: { recentMessages: string[], moodRecords: {timestamp, mood, description}[] }
- output: { emotions: string[], scores: { [label:string]: number } }

2) POST /analyze/behavior
- input: { checkins: {timestamp, taskId}[], appUsage: {hourHistogram: number[], featureClicks: {[k:string]: number}} }
- output: { preferences: { hours: number[], categories: string[] }, streakRisk: number }

3) POST /recommend/gifts
- input: { recentMessages, moodRecords, stats, weather?, location? }
- output: {
    emotions: string[],
    scores: { [label:string]: number },
    gifts: [{ title, emoji, category, description, estimatedMinutes }]
  }

## Notes
- Use m3e/bge embeddings for recall; bge-reranker for re-ranking.
- Add rule-based cooldown & dedup; finally wrap copy via LLM for "gift style".
- Add cache: key by user+date; ttl 6-12h, invalidate on significant new data.

