# frozen_string_literal: true

require 'nokogiri'

module LogoSoup
  module Core
    # Extracts width/height from SVG XML.
    class SvgDimensions
      # @param svg_string [String]
      # @return [Array(Float, Float), nil]
      def self.call(svg_string)
        raw = svg_string.to_s
        return nil if raw.empty?

        doc = Nokogiri::XML(raw) { |cfg| cfg.nonet }
        svg = doc.at_xpath("//*[local-name()='svg']")
        return nil unless svg

        view_box = svg['viewBox'] || svg['viewbox']
        if view_box
          parts = view_box.split(/[\s,]+/).filter_map do |p|
            Float(p)
          rescue ArgumentError, TypeError
            nil
          end
          return [parts[2], parts[3]] if parts.length == 4
        end

        w = numeric_dimension(svg['width'])
        h = numeric_dimension(svg['height'])
        return nil unless w && h

        [w, h]
      end

      def self.numeric_dimension(value)
        return nil if value.nil?

        num = value.to_s.strip[/[-+]?\d*\.?\d+/, 0]
        return nil if num.blank?

        Float(num)
      rescue ArgumentError
        nil
      end

      private_class_method :numeric_dimension
    end
  end
end
