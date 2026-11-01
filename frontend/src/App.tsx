import { useEffect, useState } from 'react'
import { fetchHealth, type Health } from './api'

type State =
  | { kind: 'loading' }
  | { kind: 'loaded'; health: Health }
  | { kind: 'error'; message: string }

export default function App() {
  const [state, setState] = useState<State>({ kind: 'loading' })

  useEffect(() => {
    const controller = new AbortController()
    fetchHealth(controller.signal)
      .then((health) => setState({ kind: 'loaded', health }))
      .catch((err: unknown) => {
        if (controller.signal.aborted) return
        setState({ kind: 'error', message: err instanceof Error ? err.message : String(err) })
      })
    return () => controller.abort()
  }, [])

  return (
    <main>
      <h1>Merchandising Intelligence POC</h1>
      <p className="muted">Milestone 0: system status. Synthetic data only.</p>
      <section className="status-card" aria-live="polite" aria-labelledby="status-heading">
        <h2 id="status-heading">System status</h2>
        <StatusBody state={state} />
      </section>
    </main>
  )
}

function StatusBody({ state }: { state: State }) {
  if (state.kind === 'loading') return <p>Checking API…</p>
  if (state.kind === 'error') {
    return (
      <p className="bad" role="alert">
        Cannot reach the API ({state.message}). Is the backend running on port 8000?
      </p>
    )
  }
  const { health } = state
  return (
    <dl>
      <dt>API</dt>
      <dd className={health.status === 'ok' ? 'ok' : 'bad'}>{health.status}</dd>
      <dt>Database</dt>
      <dd className={health.database === 'ok' ? 'ok' : 'bad'}>{health.database}</dd>
      <dt>Schema version</dt>
      <dd>{health.schema_version ?? 'not migrated'}</dd>
    </dl>
  )
}
