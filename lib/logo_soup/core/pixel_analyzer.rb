# frozen_string_literal: true

module LogoSoup
  module Core
    # Measures visual features from sampled RGBA pixels.
    class PixelAnalyzer
      # @return [Hash, nil]
      def self.call(
        bytes:,
        sample_width:,
        sample_height:,
        original_width:,
        original_height:,
        contrast_threshold:,
        alpha_only:,
        bg_r:,
        bg_g:,
        bg_b:
      )
        sw = sample_width
        sh = sample_height
        w = original_width
        h = original_height

        contrast_distance_sq = contrast_threshold.to_f * contrast_threshold.to_f * 3
        min_x = sw
        min_y = sh
        max_x = 0
        max_y = 0

        total_weight = 0.0
        weighted_x = 0.0
        weighted_y = 0.0

        filled_pixels = 0
        total_weighted_opacity = 0.0

        pixel_count = sw * sh
        pixel_count.times do |i|
          base = i * 4
          r = bytes[base]
          g = bytes[base + 1]
          b = bytes[base + 2]
          a = bytes[base + 3]
          next if a.nil? || a <= contrast_threshold

          if alpha_only
            weight = a * a
            opacity = a
          else
            dr = r - bg_r
            dg = g - bg_g
            db = b - bg_b
            dist_sq = (dr * dr) + (dg * dg) + (db * db)
            next if dist_sq < contrast_distance_sq

            weight = dist_sq * a
            opacity = [a, Math.sqrt(dist_sq)].min
          end

          x = i % sw
          y = (i - x) / sw

          min_x = x if x < min_x
          max_x = x if x > max_x
          min_y = y if y < min_y
          max_y = y if y > max_y

          total_weight += weight
          weighted_x += (x + 0.5) * weight
          weighted_y += (y + 0.5) * weight

          filled_pixels += 1
          total_weighted_opacity += opacity
        end

        return nil if min_x > max_x || min_y > max_y

        scan_area = (max_x - min_x + 1) * (max_y - min_y + 1)
        return nil if scan_area <= 0

        coverage_ratio = filled_pixels.to_f / scan_area
        average_opacity = filled_pixels.positive? ? (total_weighted_opacity / 255.0 / filled_pixels) : 0.0
        pixel_density = coverage_ratio * average_opacity

        scale_x = w.to_f / sw
        scale_y = h.to_f / sh

        cb_x = (min_x * scale_x).floor
        cb_y = (min_y * scale_y).floor
        cb_right = [[((max_x + 1) * scale_x).ceil.to_i, w].min, 0].max
        cb_bottom = [[((max_y + 1) * scale_y).ceil.to_i, h].min, 0].max
        content_box_width = [[cb_right - cb_x, 1].max, w].min
        content_box_height = [[cb_bottom - cb_y, 1].max, h].min

        if total_weight <= 0
          offset_x = 0.0
          offset_y = 0.0
        else
          global_center_x = (weighted_x / total_weight) * scale_x
          global_center_y = (weighted_y / total_weight) * scale_y
          local_center_x = global_center_x - cb_x
          local_center_y = global_center_y - cb_y

          geometric_center_x = content_box_width.to_f / 2
          geometric_center_y = content_box_height.to_f / 2

          offset_x = local_center_x - geometric_center_x
          offset_y = local_center_y - geometric_center_y
        end

        {
          pixel_density: pixel_density,
          content_box_width: content_box_width,
          content_box_height: content_box_height,
          visual_center_offset_x: offset_x,
          visual_center_offset_y: offset_y
        }
      end
    end
  end
end
