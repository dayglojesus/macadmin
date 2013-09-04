module MacAdmin
  
  class User < DSLocalRecord
    
    MIN_UID = 501
    
    # Override parent initialization
    # - capture the password if it exists
    # - if there's no password object param, try to get one
    # - shoehorn the password into the User record
    def initialize(args)
      if args.respond_to?(:keys)
        @password = args.delete(:password)
      end
      super(args)
      if @password
        self.send(:password=)
      else
        @password = Password.create_from_user_record(self)
      end
    end
    
    # Generic setter
    # - Accepts a Password object
    # - delegates the storage operation to the Password object itself
    def password=(password = @password)
      error = 'Argument was not a Password object'
      unless password.nil? or password.respond_to? :password
        raise ArgumentError.new(error)
      end
      @password = password
      @password.send(:store, self) unless @password.nil?
    end
    
    # Generic getter
    # - Returns Ruby Hash representation of the User's password
    def password
      return nil unless @password
      @password.password
    end
    
    # Legacy user records are determined by SHA1 password type
    # - returns boolean
    def legacy?
      @password.is_a? SaltedSHA1
    end
    
    # Does the specified resource already exist?
    # - overrides parent method; required for Legacy users
    # - checks the password if SHA1 and kicks up to parent
    def exists?
      if self.legacy?
        password_on_disk = SaltedSHA1.create_from_shadowhash_file self.generateduid[0]
        return false unless password_on_disk
        return false unless password_on_disk.password.eql? @password.password
      end
      super
    end
    
    # Create the record
    # - overrides parent method; required for Legacy users
    # - creates the password if SHA1 and kicks up to parent
    def create(file=@file)
      if self.legacy?
        return unless @password.send(:to_file, self)        
      end
      super
    end
    
    # Delete the record
    # - overrides parent method; required for Legacy users
    # - destroys the password if SHA1 and kicks up to parent
    def destroy(file=@file)
      if self.legacy?
        return unless @password.send(:rm_file, self)        
      end
      super
    end
    
    # Return a Puppet style resource manifest
    # - need to find a sensible way of doing this
    # - need to move this method into the Parent class
    def to_puppet
      puts "not implemented"
    end
    
    private
    
    # Handle required but unspecified record attributes
    # - generates missing attributes
    # - changes are merged into the composite record
    def defaults(data)
      records = all_records(@node)
      next_uid = next_id(MIN_UID, get_all_attribs_of_type(:uid, records))
      defaults = {
        'realname' => ["#{data['name'].first}"],
        'uid' => ["#{next_uid}"], 
        'home'  => ["/Users/#{data['name'].first}"],
        'shell' => ['/bin/bash'],
        'gid'   => ['20'],
        'passwd'  => ['********'],
        'comment' => [''],
      }
      super defaults.merge(data)
    end
    
  end
  
end

