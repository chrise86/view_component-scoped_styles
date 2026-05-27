# frozen_string_literal: true

require_relative "scoped_styles/version"
require_relative "scoped_styles/configuration"
require "active_support/concern"
require_relative "scoped_styles/concern"
require_relative "scoped_styles/stylist"
require_relative "scoped_styles/railtie"

module ViewComponent
  module ScopedStyles
  end
end
