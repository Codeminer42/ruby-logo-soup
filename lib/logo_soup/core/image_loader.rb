# frozen_string_literal: true

require "vips"

module LogoSoup
  module Core
    # Loads an image from disk and returns sampled RGBA bytes.
    class ImageLoader
      RGBA_CHANNELS = 4

      # @param path [String]
      # @param pixel_budget [Integer]
      # @param on_error [:raise, nil]
      # @return [Hash]
      def self.call(path:, pixel_budget:, on_error: nil)
        image = Vips::Image.new_from_file(path, access: :sequential)
        original_width = image.width
        original_height = image.height

        sample_width, sample_height, image_small = downsample(image, pixel_budget: pixel_budget)
        rgba = ensure_rgba_uchar(image_small, on_error: on_error)

        bytes = rgba.write_to_memory.bytes
        raise "Empty image bytes" if bytes.empty?

        {
          bytes: bytes,
          original_width: original_width,
          original_height: original_height,
          sample_width: sample_width,
          sample_height: sample_height
        }
      end

      def self.downsample(image, pixel_budget:)
        w = image.width
        h = image.height
        return [1, 1, image] if w <= 0 || h <= 0

        total_pixels = w * h
        ratio = total_pixels > pixel_budget ? Math.sqrt(pixel_budget.to_f / total_pixels) : 1.0
        ratio = 1.0 if ratio.nan? || ratio.infinite? || ratio <= 0

        sw = [1, (w * ratio).round].max
        sh = [1, (h * ratio).round].max

        small = ratio == 1.0 ? image : image.resize(ratio)
        if small.width != sw || small.height != sh
          hscale = sw.to_f / small.width
          vscale = sh.to_f / small.height
          small = small.resize(hscale, vscale: vscale)
        end

        [sw, sh, small]
      end

      def self.ensure_rgba_uchar(image, on_error: nil)
        img = begin
          image.colourspace("srgb")
        rescue StandardError => e
          raise e if on_error == :raise
          raise unless vips_error?(e)
          image
        end

        img = img.cast("uchar")

        if img.bands > RGBA_CHANNELS
          img = img.extract_band(0, n: RGBA_CHANNELS)
        elsif img.bands == 3
          img = img.bandjoin(255)
        elsif img.bands == 2
          gray = img.extract_band(0)
          alpha = img.extract_band(1)
          rgb = gray.bandjoin(gray).bandjoin(gray)
          img = rgb.bandjoin(alpha)
        elsif img.bands == 1
          gray = img
          rgb = gray.bandjoin(gray).bandjoin(gray)
          img = rgb.bandjoin(255)
        end

        img
      end

      def self.vips_error?(error)
        error.class.name.start_with?("Vips::")
      end

      private_class_method :downsample, :ensure_rgba_uchar, :vips_error?
    end
  end
end
