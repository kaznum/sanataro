if defined?(Fabrication::Generator::ActiveRecord4)
  module Sanataro::FabricationMassAssignment
    # this can be used with `protected_attributes' gem
    def build_instance_with_mass_assignment
      self.__instance = __klass.new(__attributes, without_protection: true)
    end
  end

  Fabrication::Generator::ActiveRecord4.send(:include,
                                             Sanataro::FabricationMassAssignment)
  Fabrication::Generator::ActiveRecord4.send(:alias_method_chain, 
                                             :build_instance, :mass_assignment)
end

