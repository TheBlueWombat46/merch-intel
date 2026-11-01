// Thin API client. In development Vite proxies /api to the FastAPI server.

export interface Health {
  status: 'ok' | 'degraded'
  database: 'ok' | 'unavailable'
  schema_version: string | null
}

export async function fetchHealth(signal?: AbortSignal): Promise<Health> {
  const resp = await fetch('/api/health', { signal })
  // 503 still carries a useful body describing what is down.
  if (!resp.ok && resp.status !== 503) {
    throw new Error(`API returned ${resp.status}`)
  }
  return (await resp.json()) as Health
}
