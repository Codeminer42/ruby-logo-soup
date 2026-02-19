# logo-soup

Framework-agnostic Ruby gem for normalizing logo rendering.

## Goal

Given an input logo (raster image or SVG), compute the CSS style string that should be applied to an `<img>` (or equivalent) so that different logos render with consistent perceived size and optional visual-center alignment.

This gem is intended to be extracted and used outside Rails. Any Rails/ActiveStorage/caching/logging concerns live in a separate adapter (not part of this gem).

## Intended API (draft)

A single entrypoint that accepts either:

- **SVG**: a `String` containing SVG XML
- **Raster image**: image bytes (e.g. `String`/`IO`) or a file path

…and returns a style string such as:

- `"width: 48px; height: 48px; object-fit: contain; display: block; transform: translate(0px, 1.9px);"`

Example (conceptual):

- `LogoSoup.style(svg: "<svg ...>", base_size: 48, align_by: "visual-center-y") #=> "..."`
- `LogoSoup.style(image_path: "./logo.png", base_size: 48) #=> "..."`

## Testing

The gem will use **RSpec** for unit testing.

## Notes

- No Rails dependencies.
- SVG parsing will use Nokogiri.
- Raster analysis requires libvips (via the `ruby-vips` gem).

## Requirements

- Ruby: `>= 2.7`, `< 4.0`
- System: `libvips` (required)

### Installing libvips

- macOS (Homebrew): `brew install vips`
- Ubuntu/Debian: `sudo apt-get update && sudo apt-get install -y libvips`

## Current Limitations

- Raster input currently supports `image_path:`.
- `image_bytes:` is supported, but currently implemented via a Tempfile + the `image_path:` pipeline.
- SVG bytes are supported when `content_type: "image/svg+xml"` (or any content type including `svg`).
