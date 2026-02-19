# frozen_string_literal: true

module LogoSoup
  module Core
    # Detects whether background should be treated as transparent and estimates
    # background RGB from the image perimeter.
    class BackgroundDetector
      QUANTIZATION_SHIFT = 5
      ALPHA_TRANSPARENCY_THRESHOLD = 128
      TRANSPARENT_PERIMETER_RATIO_THRESHOLD = 0.1

      # @param bytes [Array<Integer>] RGBA bytes
      # @param width [Integer]
      # @param height [Integer]
      # @return [Array(Boolean, Integer, Integer, Integer)] [alpha_only, bg_r, bg_g, bg_b]
      def self.call(bytes, width, height)
        levels = 1 << (8 - QUANTIZATION_SHIFT)
        bucket_count = levels * levels * levels

        bucket_counts = Array.new(bucket_count, 0)
        bucket_r = Array.new(bucket_count, 0)
        bucket_g = Array.new(bucket_count, 0)
        bucket_b = Array.new(bucket_count, 0)

        opaque_count = 0
        transparent_count = 0

        sample = lambda do |x, y|
          idx = ((y * width) + x) * 4
          a = bytes[idx + 3]
          return if a.nil?

          if a < ALPHA_TRANSPARENCY_THRESHOLD
            transparent_count += 1
            return
          end

          opaque_count += 1
          r = bytes[idx]
          g = bytes[idx + 1]
          b = bytes[idx + 2]

          key = ((((r >> QUANTIZATION_SHIFT) * levels) + (g >> QUANTIZATION_SHIFT)) * levels) + (b >> QUANTIZATION_SHIFT)
          bucket_counts[key] += 1
          bucket_r[key] += r
          bucket_g[key] += g
          bucket_b[key] += b
        end

        width.times do |x|
          sample.call(x, 0)
          sample.call(x, height - 1) if height > 1
        end

        (1...(height - 1)).each do |y|
          sample.call(0, y)
          sample.call(width - 1, y) if width > 1
        end

        total_perimeter = opaque_count + transparent_count
        transparent = total_perimeter.positive? && transparent_count > total_perimeter * TRANSPARENT_PERIMETER_RATIO_THRESHOLD
        return [true, 0, 0, 0] if transparent

        best_idx = 0
        best_count = 0
        bucket_counts.each_with_index do |count, i|
          next unless count > best_count

          best_count = count
          best_idx = i
        end

        if best_count.positive?
          bg_r = (bucket_r[best_idx].to_f / best_count).round
          bg_g = (bucket_g[best_idx].to_f / best_count).round
          bg_b = (bucket_b[best_idx].to_f / best_count).round
          [false, bg_r, bg_g, bg_b]
        else
          [false, 255, 255, 255]
        end
      end
    end
  end
end
