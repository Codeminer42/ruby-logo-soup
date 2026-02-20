# frozen_string_literal: true

module LogoSoup
  module Core
    # Computes normalized render dimensions from intrinsic dimensions.
    class DimensionCalculator
      REFERENCE_DENSITY = 0.35
      MIN_DENSITY_SCALE = 0.5
      MAX_DENSITY_SCALE = 2.0

      # @param width [Numeric]
      # @param height [Numeric]
      # @param base_size [Numeric]
      # @param scale_factor [Numeric]
      # @param density_factor [Numeric]
      # @param pixel_density [Float, nil]
      # @return [Array(Integer, Integer)]
      def self.call(width:, height:, base_size:, scale_factor:, density_factor: 0.0, pixel_density: nil)
        w = width.to_f
        h = height.to_f
        base = base_size.to_f

        return [base.round, base.round] if w <= 0 || h <= 0

        aspect_ratio = w / h
        normalized_width = (aspect_ratio**scale_factor.to_f) * base
        normalized_height = normalized_width / aspect_ratio

        df = density_factor.to_f
        if df.positive? && pixel_density
          density_ratio = pixel_density.to_f / REFERENCE_DENSITY
          if density_ratio.positive?
            density_scale = (1.0 / density_ratio)**(df * 0.5)
            clamped_scale = [[density_scale, MAX_DENSITY_SCALE].min, MIN_DENSITY_SCALE].max
            normalized_width *= clamped_scale
            normalized_height *= clamped_scale
          end
        end

        [normalized_width.round, normalized_height.round]
      end
    end
  end
end
