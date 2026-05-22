# frozen_string_literal: true

require_relative "image_loader"
require_relative "background_detector"
require_relative "pixel_analyzer"

module LogoSoup
  module Core
    # Measures raster features (density, content box, visual center offsets).
    class FeatureMeasurer
      DEFAULT_PIXEL_BUDGET = 2_048

      # @param path [String, nil] file path; mutually exclusive with buffer
      # @param buffer [String, nil] binary image bytes; mutually exclusive with path
      # @param contrast_threshold [Integer]
      # @param pixel_budget [Integer]
      # @param on_error [:raise, nil]
      # @return [Hash] features plus :source_width / :source_height
      def self.call(contrast_threshold:, path: nil, buffer: nil, pixel_budget: DEFAULT_PIXEL_BUDGET, on_error: nil)
        payload = ImageLoader.call(path: path, buffer: buffer, pixel_budget: pixel_budget, on_error: on_error)
        bytes = payload.fetch(:bytes)
        sample_width = payload.fetch(:sample_width)
        sample_height = payload.fetch(:sample_height)
        source_width = payload.fetch(:original_width)
        source_height = payload.fetch(:original_height)

        alpha_only, bg_r, bg_g, bg_b = BackgroundDetector.call(bytes, sample_width, sample_height)

        measured = PixelAnalyzer.call(
          bytes: bytes,
          sample_width: sample_width,
          sample_height: sample_height,
          original_width: source_width,
          original_height: source_height,
          contrast_threshold: contrast_threshold,
          alpha_only: alpha_only,
          bg_r: bg_r,
          bg_g: bg_g,
          bg_b: bg_b
        )

        features = measured || default_features(source_width, source_height)
        features.merge(source_width: source_width, source_height: source_height)
      end

      def self.default_features(w, h)
        {
          pixel_density: 0.5,
          content_box_width: w,
          content_box_height: h,
          visual_center_offset_x: 0.0,
          visual_center_offset_y: 0.0
        }
      end

      private_class_method :default_features
    end
  end
end
