# LogoSoup

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE.txt)
[![Coverage](https://img.shields.io/badge/coverage-86.14%25-brightgreen)](coverage/index.html)

Framework-agnostic Ruby gem for **normalizing logo rendering**.

Given an input logo (SVG or raster), LogoSoup returns an **inline CSS style string** that you can apply to an `<img>` (or equivalent) so different logos render with a consistent perceived size, with optional visual-center alignment.

This gem is inspired by the original Logo Soup project for React ([auroris/logo-soup](https://github.com/auroris/logo-soup)) developed by [Rostislav Melkumyan](https://www.sanity.io/blog/the-logo-soup-problem).

## Why

Logos often have different intrinsic sizes, padding, and visual weight. If you render them at the same width/height, they still *look* inconsistent.

LogoSoup aims to:

- Normalize sizing so logos look consistent at a given `base_size`.
- Optionally align by visual center (e.g., Y axis) for better baseline alignment.
- Stay framework-agnostic (no Rails dependencies).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logosoup'
```

Then:

```sh
bundle install
```

Or, with Bundler:

```sh
bundle add logosoup
```

## Requirements

- Ruby: `>= 2.7`, `< 4.0`
- System dependency: **libvips** (required for raster analysis)

### Installing libvips

- macOS (Homebrew):

```sh
brew install vips
```

- Ubuntu/Debian:

```sh
sudo apt-get update && sudo apt-get install -y libvips
```

## Usage

LogoSoup exposes a single entrypoint: `LogoSoup.style`.

### SVG (string)

```ruby
style = LogoSoup.style(

  svg: File.read('logo.svg'),
  base_size: 48
)

# => "width: 48px; height: 48px; object-fit: contain; display: block; transform: translate(0px, 0px);"
```

### Raster image (file path)

```ruby
style = LogoSoup.style(
  image_path: 'logo.png',
  base_size: 48
)
```

### Bytes (IO/String)

```ruby
bytes = File.binread('logo.webp')

style = LogoSoup.style(
  image_bytes: bytes,
  content_type: 'image/webp',
  base_size: 48
)
```

If `content_type` includes `svg` (e.g. `image/svg+xml`), `image_bytes:` is treated as SVG and handled by the SVG pipeline.

## API

### `LogoSoup.style`

```ruby
LogoSoup.style(
  svg: nil,
  image_path: nil,
  image_bytes: nil,
  content_type: nil,
  base_size:,
  on_error: nil,
  **options
)
```

#### Inputs (choose one)

- `svg:` String containing SVG XML
- `image_path:` filesystem path to an image (PNG/JPG/WebP/GIF/TIFF, etc.)
- `image_bytes:` String/IO of image bytes

#### Required

- `base_size:` Integer (pixels). Used as the normalization target and also as fallback width/height.

#### Error handling

- `on_error: nil` (default): return a fallback style (`width/height = base_size`, no transform)
- `on_error: :raise`: re-raise the original exception

#### Options (with defaults)

These map directly to `LogoSoup::Style::DEFAULTS`:

- `scale_factor:` `0.5`
- `density_aware:` `true`
- `density_factor:` `0.5`
- `contrast_threshold:` `10`
- `align_by:` `'visual-center-y'`
- `pixel_budget:` `2048`

Notes:

- Raster images are analyzed with libvips to estimate features (e.g. pixel density / content box / visual center offsets) that inform sizing and transforms.
- For SVG input, LogoSoup currently uses intrinsic SVG dimensions and skips raster feature measurement.

## Output

The return value is a single inline CSS string including (at least):

- `width: ...px;`
- `height: ...px;`
- `object-fit: contain;`
- `display: block;`
- `transform: ...` (only when alignment produces a non-nil transform)

This is designed to be applied directly to an `<img>` tag or any element that supports these properties.

## Testing

Run the test suite:

```sh
bundle exec rake spec
```

### Coverage

Generate a local coverage report:

```sh
bundle exec rake spec:coverage
```

This writes HTML reports to `coverage/index.html`.

The badge at the top of this README reflects the last recorded SimpleCov result in `coverage/.last_run.json` (current line coverage: **86.14%**; branch coverage in that file: **53.17%**).

## Development

```sh
bundle install
bundle exec rake spec
```

## Contributing

Bug reports and pull requests are welcome.

- Keep changes focused and add specs where it makes sense.
- If you change behavior, update `CHANGELOG.md`

## License

Released under the MIT License. See `LICENSE.txt`.
