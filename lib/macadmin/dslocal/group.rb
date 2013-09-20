module MacAdmin
  
  class Group < DSLocalRecord
    
    MIN_GID = 501
    
    def initialize(args)
      @member_class = User  unless defined? @member_class
      @group_class  = Group unless defined? @group_class
      super args
    end
    
    # Examine the object's users array for "member"
    # - single param: the name of a user (String)
    def has_user?(member)
      self[:users].member? member
    end
    
    # Add a member to the object's users array
    # - single param: the name of a user (String)
    def add_user(member)
      user = @member_class.new :name => member, :node => self.node
      raise unless user.exists?
      self[:users] << member
      self[:users].uniq!
    end
    
    # Remove a member from the object's users array
    # - single param: the name of a user (String)
    def rm_user(member)
      self[:users].delete member
    end
    
    # Examine the object's groupmembers array for "member"
    # - single param: the name of a group (String)
    def has_groupmember?(member)
      group = @group_class.new :name => member, :node => self.node
      return false unless group.exists?
      self[:groupmembers].member? group.generateduid.first
    end
    
    # Add a member to the object's groupmembers array
    # - single param: the name of a group (String)    
    def add_groupmember(member)
      group = @group_class.new :name => member, :node => self.node
      raise unless group.exists?
      self[:groupmembers] << group.generateduid.first 
      self[:groupmembers].uniq!
    end
    
    # Remove a member from the object's groupmembers array
    # - single param: the name of a group (String)
    def rm_groupmember(member)
      group = @group_class.new :name => member, :node => self.node
      return nil unless group.exists?
      self[:groupmembers].delete group.generateduid.first
    end
    
    private
    
    # Handle required but unspecified record attributes
    # - generates missing attributes
    # - changes are merged into the composite record
    def defaults(data)
      records = all_records(@node)
      next_gid = next_id(MIN_GID, get_all_attribs_of_type(:gid, records))
      defaults = {
        'realname' => ["#{data['name'].first.capitalize}"],
        'gid'   => ["#{next_gid}"],
        'passwd'  => ['*'],
        'groupmembers' => [],
        'users' => [],
      }
      super defaults.merge(data)
    end
    
  end
  
end