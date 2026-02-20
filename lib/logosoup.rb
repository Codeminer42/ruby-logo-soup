# frozen_string_literal: true

require_relative "logosoup/version"

require_relative "logosoup/core/css"
require_relative "logosoup/core/svg_dimensions"
require_relative "logosoup/core/dimension_calculator"
require_relative "logosoup/core/visual_center_transform"

require_relative "logosoup/core/image_loader"
require_relative "logosoup/core/background_detector"
require_relative "logosoup/core/pixel_analyzer"
require_relative "logosoup/core/feature_measurer"

require_relative "logosoup/style"

module LogoSoup
	class Error < StandardError; end

	def self.style(**kwargs)
		Style.call(**kwargs)
	end
end
