require 'config_reader'

class AppConfig < ConfigReader
  self.config_file = 'config/config.yml'
end
