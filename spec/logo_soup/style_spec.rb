# frozen_string_literal: true

require 'tempfile'

RSpec.describe LogoSoup do
  describe '.style' do
    it 'returns a deterministic fallback style for empty input' do
      style = described_class.style(base_size: 48)
      expect(style).to include('width: 48px;')
      expect(style).to include('height: 48px;')
      expect(style).to include('object-fit: contain;')
      expect(style).to include('display: block;')
      expect(style).not_to include('transform:')
    end

    it 'computes width/height from SVG viewBox' do
      svg = '<svg viewBox="0 0 200 100" xmlns="http://www.w3.org/2000/svg"></svg>'
      style = described_class.style(svg: svg, base_size: 48, scale_factor: 0.5, align_by: 'bounds')

      expect(style).to include('object-fit: contain;')
      expect(style).to include('display: block;')
      expect(style).to match(/width: \d+px;/)
      expect(style).to match(/height: \d+px;/)
      expect(style).not_to include('transform:')
    end

    it 'raises when SVG numeric parsing fails and on_error: :raise is set' do
      svg = '<svg viewBox="0 0 x 100" xmlns="http://www.w3.org/2000/svg"></svg>'
      expect do
        described_class.style(svg: svg, base_size: 48, on_error: :raise)
      end.to raise_error(StandardError)
    end

    it 'produces a non-zero transform for an off-center raster image' do
      file = Tempfile.new(['logo_soup', '.png'])
      file.close

      # White background with a black rectangle near the top => visual center offset.
      img = Vips::Image.black(120, 120).new_from_image([255, 255, 255])
      img = img.draw_rect([0, 0, 0], 40, 10, 40, 20, fill: true)
      img.pngsave(file.path)

      style = described_class.style(
        image_path: file.path,
        base_size: 48,
        scale_factor: 0.5,
        density_aware: false,
        align_by: 'visual-center-y',
        contrast_threshold: 10
      )

      expect(style).to include('object-fit: contain;')
      expect(style).to include('display: block;')
      expect(style).to include('width: ')
      expect(style).to include('height: ')
      expect(style).to include('transform: translate(')
    ensure
      file.unlink if file
    end
    it 'accepts image_bytes for raster input' do
      img = Vips::Image.black(120, 120).new_from_image([255, 255, 255])
      img = img.draw_rect([0, 0, 0], 40, 10, 40, 20, fill: true)
      bytes = img.pngsave_buffer

      style = described_class.style(
        image_bytes: bytes,
        content_type: 'image/png',
        base_size: 48,
        scale_factor: 0.5,
        density_aware: false,
        align_by: 'visual-center-y',
        contrast_threshold: 10
      )

      expect(style).to include('width: ')
      expect(style).to include('height: ')
      expect(style).to include('transform: translate(')
    end

    it 'can raise instead of falling back with on_error: :raise' do
      file = Tempfile.new(['logo_soup', '.png'])
      path = file.path
      file.close
      file.unlink

      expect do
        described_class.style(image_path: path, base_size: 48, on_error: :raise)
      end.to raise_error(StandardError)
    end
  end
end
