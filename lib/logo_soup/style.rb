# frozen_string_literal: true

require "tempfile"
require "vips"

module LogoSoup
  # Composes the core logic into a single style string.
  class Style
    DEFAULTS = {
      scale_factor: 0.5,
      density_aware: true,
      density_factor: 0.5,
      contrast_threshold: 10,
      align_by: "visual-center-y",
      pixel_budget: 2_048
    }.freeze

    # @param on_error [:raise, nil] error handling strategy
    #   - nil (default): return fallback style
    #   - :raise: re-raise the original exception
    # @return [String] inline CSS style
    def self.call(base_size:, svg: nil, image_path: nil, image_bytes: nil, content_type: nil, on_error: nil, **options)
      opts = DEFAULTS.merge(options).merge(base_size: base_size)

      if svg
        handle_svg(svg, opts: opts, on_error: on_error)
      elsif image_path
        handle_image_path(image_path, opts: opts, on_error: on_error)
      elsif image_bytes
        handle_image_bytes(image_bytes, content_type: content_type, opts: opts, on_error: on_error)
      else
        fallback_style(opts)
      end
    rescue StandardError => e
      handle_error(e, opts: opts, on_error: on_error)
    end

    def self.handle_svg(svg_string, opts:, on_error:)
      intrinsic_w, intrinsic_h = Core::SvgDimensions.call(svg_string, on_error: on_error) || [0.0, 0.0]

      features =
        if wants_visual_center?(opts.fetch(:align_by, nil))
          measure_svg_features(svg_string, intrinsic_width: intrinsic_w, intrinsic_height: intrinsic_h, opts: opts, on_error: on_error)
        else
          empty_features
        end

      build_style(
        intrinsic_width: intrinsic_w,
        intrinsic_height: intrinsic_h,
        features: features,
        **opts
      )
    end

    def self.handle_image_path(image_path, opts:, on_error:)
      # Raster analysis is required; libvips must be installed.
      image = Vips::Image.new_from_file(image_path, access: :sequential)
      intrinsic_w = image.width
      intrinsic_h = image.height

      features = Core::FeatureMeasurer.call(
        path: image_path,
        contrast_threshold: opts.fetch(:contrast_threshold).to_i,
        pixel_budget: opts.fetch(:pixel_budget).to_i,
        on_error: on_error
      )

      build_style(
        intrinsic_width: intrinsic_w,
        intrinsic_height: intrinsic_h,
        features: features,
        **opts
      )
    end

    def self.handle_image_bytes(image_bytes, content_type:, opts:, on_error:)
      bytes = image_bytes.respond_to?(:read) ? image_bytes.read : image_bytes
      bytes = bytes.to_s

      if content_type.to_s.include?("svg")
        svg_string = bytes.dup.force_encoding("UTF-8")
        return handle_svg(svg_string, opts: opts, on_error: on_error)
      end

      file = nil
      ext = file_extension_for(content_type)
      file = Tempfile.new(["logo_soup", ext])
      file.binmode
      file.write(bytes)
      file.flush
      file.close

      handle_image_path(file.path, opts: opts, on_error: on_error)
    ensure
      file.unlink if file
    end

    def self.handle_error(error, opts:, on_error:)
      case on_error
      when :raise
        raise error
      else
        fallback_style(opts)
      end
    end

    def self.wants_visual_center?(align_by)
      mode = align_by.to_s.strip
      %w[visual-center visual-center-x visual-center-y].include?(mode)
    end

    def self.measure_svg_features(svg_string, intrinsic_width:, intrinsic_height:, opts:, on_error:)
      return empty_features if intrinsic_width.to_f <= 0 || intrinsic_height.to_f <= 0

      file = Tempfile.new(["logo_soup", ".svg"])
      file.binmode
      file.write(svg_string.to_s)
      file.flush
      file.close

      rendered = Vips::Image.new_from_file(file.path, access: :sequential)
      rendered_w = rendered.width.to_f
      rendered_h = rendered.height.to_f
      return empty_features if rendered_w <= 0 || rendered_h <= 0

      measured = Core::FeatureMeasurer.call(
        path: file.path,
        contrast_threshold: opts.fetch(:contrast_threshold).to_i,
        pixel_budget: opts.fetch(:pixel_budget).to_i,
        on_error: on_error
      )

      scale_x = intrinsic_width.to_f / rendered_w
      scale_y = intrinsic_height.to_f / rendered_h

      scaled = measured.dup
      scaled[:content_box_width] = scaled[:content_box_width].to_f * scale_x if scaled[:content_box_width].is_a?(Numeric)
      scaled[:content_box_height] = scaled[:content_box_height].to_f * scale_y if scaled[:content_box_height].is_a?(Numeric)
      scaled[:visual_center_offset_x] = scaled[:visual_center_offset_x].to_f * scale_x if scaled[:visual_center_offset_x].is_a?(Numeric)
      scaled[:visual_center_offset_y] = scaled[:visual_center_offset_y].to_f * scale_y if scaled[:visual_center_offset_y].is_a?(Numeric)
      scaled
    rescue StandardError => e
      raise e if on_error == :raise

      empty_features
    ensure
      file.unlink if file
    end

    def self.file_extension_for(content_type)
      case content_type.to_s
      when "image/png" then ".png"
      when "image/jpeg", "image/jpg" then ".jpg"
      when "image/webp" then ".webp"
      when "image/gif" then ".gif"
      when "image/tiff" then ".tif"
      else
        ".img"
      end
    end

    def self.build_style(
      intrinsic_width:,
      intrinsic_height:,
      features:,
      base_size:,
      scale_factor:,
      density_aware:,
      density_factor:,
      align_by:,
      **_unused
    )
      pixel_density = density_aware ? features[:pixel_density] : nil
      effective_density_factor = density_aware ? density_factor.to_f : 0.0

      normalized_w, normalized_h = Core::DimensionCalculator.call(
        width: intrinsic_width,
        height: intrinsic_height,
        base_size: base_size,
        scale_factor: scale_factor,
        density_factor: effective_density_factor,
        pixel_density: pixel_density
      )

      transform = Core::VisualCenterTransform.call(
        features: features,
        normalized_width: normalized_w,
        normalized_height: normalized_h,
        align_by: align_by,
        intrinsic_width: intrinsic_width,
        intrinsic_height: intrinsic_height
      )

      Core::Css.style_string(
        width: "#{normalized_w}px",
        height: "#{normalized_h}px",
        object_fit: "contain",
        display: "block",
        transform: transform
      )
    end

    def self.fallback_style(opts)
      base = opts.fetch(:base_size).to_i
      Core::Css.style_string(
        width: "#{base}px",
        height: "#{base}px",
        object_fit: "contain",
        display: "block",
        transform: nil
      )
    end

    def self.empty_features
      {
        pixel_density: nil,
        content_box_width: nil,
        content_box_height: nil,
        visual_center_offset_x: nil,
        visual_center_offset_y: nil
      }
    end

    private_class_method :build_style,
                         :fallback_style,
                         :empty_features,
                         :file_extension_for,
                         :handle_error,
                         :handle_svg,
                         :handle_image_path,
                         :handle_image_bytes,
                         :measure_svg_features,
                         :wants_visual_center?
  end
end
