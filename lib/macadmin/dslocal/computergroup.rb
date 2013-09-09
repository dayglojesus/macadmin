module MacAdmin
  
  class ComputerGroup < Group
    
    MIN_GID = 501
    
    def initialize(args)
      @member_class = Computer      unless defined? @member_class
      @group_class  = ComputerGroup unless defined? @group_class
      super args
    end
    
  end
  
end