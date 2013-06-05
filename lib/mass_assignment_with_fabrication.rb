# this can be used with `protected_attributes' gem
# for fabrication >= 2.7.2 (https://github.com/paulelliott/fabrication/commit/44d9942375475aa2e4f4a31336f8cce08f736acd)
if defined?(Fabrication::Generator::ActiveRecord)
  module Sanataro::FabricationMassAssignment
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :without_protection?, :mass_assignment
      end
    end
    module ClassMethods
      def without_protection_with_mass_assignment?
        true
      end
    end
  end

  Fabrication::Generator::ActiveRecord.send :include, Sanataro::FabricationMassAssignment
end

