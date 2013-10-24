require 'rails/generators'  

module SnapplerContable
  class InitializerGenerator < ::Rails::Generators::Base
    def create_initializer_file
      create_file "config/initializers/snappler_contable.rb", "# Agregar el array de operaciones validas\nSnapplerContable.valid_operations = [:pago]\n\n# Moneda por defecto\nSnapplerContable.default_currency = 'ARS'"
    end
  end
end