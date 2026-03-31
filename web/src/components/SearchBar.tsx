/**
 * SearchBar.jsx
 * Hotel name / country / city search using Fuse.js fuzzy matching.
 * (Couchbase Lite JS does not support MATCH() full-text search indexes.)
 */



interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  onClear: () => void;
}

export default function SearchBar({ value, onChange, onClear }: SearchBarProps) {
  return (
    <div className="search-bar">
      <svg className="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <circle cx="11" cy="11" r="8" />
        <line x1="21" y1="21" x2="16.65" y2="16.65" />
      </svg>
      <input
        id="hotel-search"
        type="text"
        className="search-input"
        placeholder="Search hotels by name, city, or country…"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        aria-label="Search hotels"
      />
      {value && (
        <button className="search-clear" onClick={onClear} aria-label="Clear search">
          ✕
        </button>
      )}
    </div>
  );
}
