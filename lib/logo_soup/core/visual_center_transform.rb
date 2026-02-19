# frozen_string_literal: true

require_relative 'css'

module LogoSoup
  module Core
    # Computes a CSS translate() transform to align by visual center.
    class VisualCenterTransform
      # @param features [Hash]
      # @param normalized_width [Numeric]
      # @param normalized_height [Numeric]
      # @param align_by [String, Symbol]
      # @param intrinsic_width [Numeric]
      # @param intrinsic_height [Numeric]
      # @return [String, nil]
      def self.call(features:, normalized_width:, normalized_height:, align_by:, intrinsic_width:, intrinsic_height:)
        mode = align_by.to_s.strip
        return nil if mode.empty? || mode == 'bounds'

        offset_x = features[:visual_center_offset_x]
        offset_y = features[:visual_center_offset_y]
        return nil unless offset_x.is_a?(Numeric) && offset_y.is_a?(Numeric)

        content_w = features[:content_box_width].to_f
        content_h = features[:content_box_height].to_f
        content_w = intrinsic_width.to_f if content_w <= 0
        content_h = intrinsic_height.to_f if content_h <= 0
        return nil if content_w <= 0 || content_h <= 0

        scale_x = normalized_width.to_f / content_w
        scale_y = normalized_height.to_f / content_h

        dx = %w[visual-center visual-center-x].include?(mode) ? (-offset_x.to_f * scale_x) : 0.0
        dy = %w[visual-center visual-center-y].include?(mode) ? (-offset_y.to_f * scale_y) : 0.0

        dx_fmt = Css.fmt_tenth_px(dx)
        dy_fmt = Css.fmt_tenth_px(dy)
        return nil if dx_fmt == '0' && dy_fmt == '0'

        "translate(#{dx_fmt}px, #{dy_fmt}px)"
      end
    end
  end
end
