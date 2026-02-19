# frozen_string_literal: true

module LogoSoup
  module Core
    # CSS utilities.
    module Css
      module_function

      # Formats a numeric value rounded to 1 decimal place.
      #
      # @param value [Numeric]
      # @return [String]
      def fmt_tenth_px(value)
        rounded = (value.to_f * 10).round / 10.0
        rounded = 0.0 if rounded.abs < 1e-9
        rounded.to_i == rounded ? rounded.to_i.to_s : rounded.to_s
      end

      # Builds an inline style string from a hash.
      #
      # @param styles [Hash{Symbol=>String,nil}]
      # @return [String]
      def style_string(styles)
        styles.compact.map { |key, val| "#{key.to_s.tr('_', '-')}: #{val};" }.join(' ')
      end
    end
  end
end
