module MacAdmin
  
  # ComputerGroup
  # - creates and manages AMC OS X Computer Groups
  # - inherits from MacAdmin::Group
  # - params: :name, :realname, :gid
  class ComputerGroup < Group
    
    MIN_GID = 501
    
    def initialize(args)
      @member_class = Computer      unless defined? @member_class
      @group_class  = ComputerGroup unless defined? @group_class
      super args
    end
    
  end
  
end