# frozen_string_literal: true

module VAOS
  class AVSConfiguration < VAOS::Configuration
    def base_path
      Settings.va_mobile.url
    end
  end
end
