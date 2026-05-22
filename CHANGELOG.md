# Changelog

## Unreleased

### Added
- Security warning in README clarifying that LogoSoup is intended for trusted
  asset pipelines only — not for user uploads or other untrusted sources.
- `Dockerfile` for development and CI, with Ruby 3.3 + libvips + librsvg.
- Auto-updating coverage badge. The `Coverage Main` workflow now runs on
  every push to `main`, generates a shields.io endpoint JSON from
  `coverage/.last_run.json`, and publishes it to an orphan `badges` branch.
  The README badge points to that file via `shields.io/endpoint`; no external
  coverage service signup required.

### Changed
- `LogoSoup.style` now warns to stderr when callers pass unknown option keys
  (typos like `align:` instead of `align_by:`), surfacing what used to be a
  silent footgun.
- `image_bytes:` that is neither a `String` nor an IO-like object now raises
  `ArgumentError` instead of producing a cryptic libvips error.
- SVG bytes coming in via `image_bytes:` + `content_type: "image/svg+xml"` are
  now safely transcoded to UTF-8 (replacing invalid sequences) instead of being
  bare `force_encoding`'d, so SVGs with a BOM or in a non-UTF-8 encoding parse
  without crashing.
- Internal refactor: replaced `Tempfile` round-trips with
  `Vips::Image.new_from_buffer` for SVG and raster bytes; removed a duplicate
  vips decode in `handle_image_path`; switched pixel loops from
  `Array<Integer>` (`String#bytes`) to binary `String` + `String#getbyte` to
  reduce per-call allocations.
- Bumped `.rubocop.yml` `TargetRubyVersion` from 2.7 to 3.1 to match the
  gemspec's `required_ruby_version`.

### Fixed
- `SvgDimensions.numeric_dimension` no longer calls `String#blank?` from
  ActiveSupport (a dev-only dep); replaced with stdlib `nil? || empty?`. The
  previous code would raise `NoMethodError` at runtime for SVGs without a
  viewBox.
- `ImageLoader.ensure_rgba_uchar` no longer crashes on a theoretical 0-band
  image; behaviour for 0-band input now matches the original implementation
  (no-op).

## 0.1.3

- Use isotype logo for better light/dark mode README compatibility.
- Add Codeminer42 logo and reference to the original Logo Soup article.

## 0.1.2

- Bump version (no behavioural change).
- Relax nokogiri version constraint to allow 1.19.

## 0.1.1

- Rename gem entry point from `logo_soup` to `logosoup` and migrate lib paths.
- Pin explicit version constraints for `rake`, `rubocop-github`, and
  `rubocop-performance`.

## 0.1.0

- Initial gem scaffold.
- `LogoSoup.style` supports SVG strings, raster image paths, and image bytes.
- Visual-center alignment, density-aware sizing, and graceful fallback.
