module MacAdmin
  
  # Computer
  # - creates and manages Mac OS X Computer records
  # - params: :name, :realname, :en_address
  class Computer < DSLocalRecord
    
    # Handle required but unspecified record attributes
    # - generates missing attributes
    # - changes are merged into the composite record
    def defaults(data)
      mac_address = get_primary_mac_address
      defaults = {
        'realname'   => ["#{data['name'].first.capitalize}"],
        'en_address' => [mac_address]
      }
      super defaults.merge(data)
    end
    
  end
  
end