import { render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import App from './App'

function mockFetch(impl: () => Promise<Response>) {
  vi.stubGlobal('fetch', vi.fn(impl))
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('App system status', () => {
  it('shows a loading state first', () => {
    mockFetch(() => new Promise(() => {}))
    render(<App />)
    expect(screen.getByText('Checking API…')).toBeInTheDocument()
  })

  it('shows API, database and schema version when healthy', async () => {
    mockFetch(async () =>
      Response.json({ status: 'ok', database: 'ok', schema_version: '0001' }),
    )
    render(<App />)
    expect(await screen.findByText('0001')).toBeInTheDocument()
    expect(screen.getAllByText('ok')).toHaveLength(2)
  })

  it('shows degraded status when the database is down', async () => {
    mockFetch(async () =>
      Response.json(
        { status: 'degraded', database: 'unavailable', schema_version: null },
        { status: 503 },
      ),
    )
    render(<App />)
    expect(await screen.findByText('unavailable')).toBeInTheDocument()
    expect(screen.getByText('not migrated')).toBeInTheDocument()
  })

  it('shows an error when the API cannot be reached', async () => {
    mockFetch(async () => {
      throw new TypeError('Failed to fetch')
    })
    render(<App />)
    expect(await screen.findByRole('alert')).toHaveTextContent('Cannot reach the API')
  })
})
