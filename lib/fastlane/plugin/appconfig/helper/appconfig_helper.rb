require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class AppconfigHelper
      # class methods that you define here become available in your action
      # as `Helper::AppconfigHelper.your_method`
      #
      def self.show_message
        UI.message('Hello from the appconfig plugin helper!')
      end
    end
  end
end

module Match
  class Encrypt
    def appconfig_encrypt(path: nil, password: nil)
      encrypt(path: path, password: password)
    end
    def appconfig_decrypt(path: nil, password: nil)
      decrypt(path: path, password: password)
    end
  end
end
