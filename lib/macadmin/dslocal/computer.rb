module MacAdmin
  
  class Computer < DSLocalRecord
    
    # Handle required but unspecified record attributes
    # - generates missing attributes
    # - changes are merged into the composite record
    def defaults(data)
      defaults = {
        'realname' => ["#{data['name'].first}"],
      }
      super defaults.merge(data)
    end
    
  end
  
end