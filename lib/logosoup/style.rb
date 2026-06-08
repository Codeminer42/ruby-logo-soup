# frozen_string_literal: true

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
      pixel_budget: Core::FeatureMeasurer::DEFAULT_PIXEL_BUDGET
    }.freeze

    # @param on_error [:raise, nil] error handling strategy
    #   - nil (default): return fallback style
    #   - :raise: re-raise the original exception
    # @return [String] inline CSS style
    def self.call(base_size:, svg: nil, image_path: nil, image_bytes: nil, content_type: nil, on_error: nil, **options)
      warn_unknown_options(options)
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

    def self.warn_unknown_options(options)
      unknown = options.keys - DEFAULTS.keys
      return if unknown.empty?

      warn "[LogoSoup] ignoring unknown option(s): #{unknown.join(', ')} " \
           "(known: #{DEFAULTS.keys.join(', ')})"
    end

    def self.handle_svg(svg_string, opts:, on_error:)
      intrinsic_w, intrinsic_h = Core::SvgDimensions.call(svg_string, on_error: on_error) || [0.0, 0.0]

      features =
        if Core::VisualCenterTransform.visual_center?(opts.fetch(:align_by, nil))
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
      analyze_raster(path: image_path, opts: opts, on_error: on_error)
    end

    def self.handle_image_bytes(image_bytes, content_type:, opts:, on_error:)
      bytes = image_bytes.respond_to?(:read) ? image_bytes.read : image_bytes
      unless bytes.is_a?(String)
        raise ArgumentError, "image_bytes must be a String or an IO-like object (got #{bytes.class})"
      end

      if content_type.to_s.include?("svg")
        return handle_svg(coerce_to_utf8(bytes), opts: opts, on_error: on_error)
      end

      analyze_raster(buffer: bytes, opts: opts, on_error: on_error)
    end

    def self.coerce_to_utf8(bytes)
      bytes.dup.force_encoding(Encoding::BINARY)
           .encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end

    def self.analyze_raster(opts:, on_error:, path: nil, buffer: nil)
      features = Core::FeatureMeasurer.call(
        path: path,
        buffer: buffer,
        contrast_threshold: opts.fetch(:contrast_threshold).to_i,
        pixel_budget: opts.fetch(:pixel_budget).to_i,
        on_error: on_error
      )

      build_style(
        intrinsic_width: features[:source_width],
        intrinsic_height: features[:source_height],
        features: features,
        **opts
      )
    end

    def self.handle_error(error, opts:, on_error:)
      case on_error
      when :raise
        raise error
      else
        fallback_style(opts)
      end
    end

    def self.measure_svg_features(svg_string, intrinsic_width:, intrinsic_height:, opts:, on_error:)
      return empty_features if intrinsic_width.to_f <= 0 || intrinsic_height.to_f <= 0

      buffer = svg_string.to_s
      measured = Core::FeatureMeasurer.call(
        buffer: buffer,
        contrast_threshold: opts.fetch(:contrast_threshold).to_i,
        pixel_budget: opts.fetch(:pixel_budget).to_i,
        on_error: on_error
      )

      rendered_w = measured[:source_width].to_f
      rendered_h = measured[:source_height].to_f
      return empty_features if rendered_w <= 0 || rendered_h <= 0

      scale_x = intrinsic_width.to_f / rendered_w
      scale_y = intrinsic_height.to_f / rendered_h

      scales = {
        content_box_width: scale_x,
        content_box_height: scale_y,
        visual_center_offset_x: scale_x,
        visual_center_offset_y: scale_y
      }
      scaled = measured.dup
      scales.each do |key, scale|
        scaled[key] = scaled[key].to_f * scale if scaled[key].is_a?(Numeric)
      end
      scaled
    rescue StandardError => e
      raise e if on_error == :raise

      empty_features
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

    private_class_method :analyze_raster,
                         :build_style,
                         :coerce_to_utf8,
                         :fallback_style,
                         :empty_features,
                         :handle_error,
                         :handle_svg,
                         :handle_image_path,
                         :handle_image_bytes,
                         :measure_svg_features,
                         :warn_unknown_options
  end
end
