/**
 * App.test.jsx
 *
 * Smoke test: verifies the App component renders without crashing.
 * Full CBL JS SDK is mocked.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from '../App';

// Mock DatabaseManager to prevent real CBL initialization in tests
vi.mock('../model/DatabaseManager', () => ({
  databaseManager: {
    initialize: vi.fn(async () => {}),
    getDatabase: vi.fn(() => ({
      createQuery: vi.fn(() => ({
        execute: vi.fn(async () => []),
      })),
    })),
    getCollection: vi.fn(() => ({
      addChangeListener: vi.fn(),
      removeChangeListener: vi.fn(),
    })),
    addChangeListener: vi.fn(),
    removeChangeListener: vi.fn(),
    setupReplication: vi.fn(async () => ({
      start: vi.fn(),
      addChangeListener: vi.fn(),
    })),
    close: vi.fn(async () => {}),
  },
}));

// Mock fetch for config.json (no Capella config in test env)
global.fetch = vi.fn(async () => ({
  json: async () => ({
    capellaEndpointUrl: 'your-endpoint',
    username: '',
    password: '',
  }),
}));

describe('App (smoke test)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders the app title without crashing', async () => {
    render(<App />);
    expect(screen.getByText(/Hotels/i)).toBeInTheDocument();
  });

  it('renders the Add Hotel button', async () => {
    render(<App />);
    const btn = document.getElementById('add-hotel-btn');
    expect(btn).not.toBeNull();
  });

  it('renders the search input', async () => {
    render(<App />);
    const input = document.getElementById('hotel-search');
    expect(input).not.toBeNull();
  });
});
