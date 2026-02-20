# frozen_string_literal: true

require_relative "logo_soup/version"

require_relative "logo_soup/core/css"
require_relative "logo_soup/core/svg_dimensions"
require_relative "logo_soup/core/dimension_calculator"
require_relative "logo_soup/core/visual_center_transform"

require_relative "logo_soup/core/image_loader"
require_relative "logo_soup/core/background_detector"
require_relative "logo_soup/core/pixel_analyzer"
require_relative "logo_soup/core/feature_measurer"

require_relative "logo_soup/style"

module LogoSoup
  class Error < StandardError; end

  # Public API.
  #
  # @return [String] inline CSS style string
  def self.style(**kwargs)
    Style.call(**kwargs)
  end
end
