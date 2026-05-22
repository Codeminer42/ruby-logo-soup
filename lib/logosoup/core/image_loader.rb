# frozen_string_literal: true

require "vips"

module LogoSoup
  module Core
    # Loads an image from disk and returns sampled RGBA bytes.
    class ImageLoader
      RGBA_CHANNELS = 4

      # @param path [String, nil] file path; mutually exclusive with buffer
      # @param buffer [String, nil] binary image bytes; mutually exclusive with path
      # @param pixel_budget [Integer]
      # @param on_error [:raise, nil]
      # @return [Hash]
      def self.call(pixel_budget:, path: nil, buffer: nil, on_error: nil)
        image =
          if buffer
            Vips::Image.new_from_buffer(buffer, "", access: :sequential)
          else
            Vips::Image.new_from_file(path, access: :sequential)
          end
        original_width = image.width
        original_height = image.height

        sample_width, sample_height, image_small = downsample(image, pixel_budget: pixel_budget)
        rgba = ensure_rgba_uchar(image_small, on_error: on_error)

        bytes = rgba.write_to_memory
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

        case img.bands
        when 0
          img
        when 1
          img.bandjoin(img).bandjoin(img).bandjoin(255)
        when 2
          gray = img.extract_band(0)
          alpha = img.extract_band(1)
          gray.bandjoin(gray).bandjoin(gray).bandjoin(alpha)
        when 3
          img.bandjoin(255)
        when RGBA_CHANNELS
          img
        else
          img.extract_band(0, n: RGBA_CHANNELS)
        end
      end

      def self.vips_error?(error)
        error.class.name.start_with?("Vips::")
      end

      private_class_method :downsample, :ensure_rgba_uchar, :vips_error?
    end
  end
end
