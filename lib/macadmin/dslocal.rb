module MacAdmin
  
  # Stub Error class
  class DSLocalError < StandardError
  end
  
  # DSLocalRecord (super class)
  # - this is the raw constructor class for DSLocal records
  # - records of 'type' should be created using one of the provided subclasses
  # - this class delegates to Hash and therefore behaves as though it were one
  # - added method_missing? to do fancy dot-style attribute returns
  class DSLocalRecord < DelegateClass(Hash)
    
    include MacAdmin::Common
    include MacAdmin::MCX
    
    # Where all the files on disk live
    DSLOCAL_ROOT = '/private/var/db/dslocal/nodes'
    
    # Some reader attributes for introspection and debugging
    attr_reader   :data, :composite, :real, :file, :record, :node
    attr_accessor :file
    
    class << self
      
      # Inits a record from a file on disk
      # - param is a path to a DSLocal Property List file
      # - if file is invalid, return nil
      def init_with_file(file)
        data = load_plist file
        return nil unless data
        self.new :name => data['name'].first, :file => file, :real => data
      end
      
    end
    
    # Create a new DSLocalRecord
    # - this method is not meant to be called directly; use subclasses instead
    # - params are valid DSLocalRecord attributes
    # - when a node is not specified, 'Default' is assumed
    def initialize(args)
      @real = (args.delete(:real) { nil }) unless args.is_a? String
      @data = normalize(args)
      @name = @data['name'].first
      @record_type = record_type
      @node = (@data.delete('node') { ['Default'] }).first.to_s
      @file = (@data.delete('file') { ["#{DSLOCAL_ROOT}/#{@node}/#{@record_type + 's'}/#{@name}.plist"] }).first.to_s
      @record = synthesize(@data)
      super(@record)
    end
    
    # Does the specified resource already exist?
    # - returns Boolean
    def exists?
      @real = load_plist @file
      @composite.eql? @real
    end
    
    # Create the record
    # - simply writes the compiled Hash to disk
    # - converts ShadowHashData attrib to CFPropertyList::Blob before writing
    # - will accept an alternate path than the default; useful for debugging
    def create(file = @file)
      out = @record.dup
      if shadowhashdata = out['ShadowHashData']
        out['ShadowHashData'] = [CFPropertyList::Blob.new(shadowhashdata.first)]
      end
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(out)
      plist.save(file, CFPropertyList::List::FORMAT_BINARY)
    end
    
    # Delete the record
    # - removes the file representing the record from disk
    # - will accept an alternate path than the default; useful for debugging
    # - returns true if the file was destroyed or does not exist; false otherwise
    def destroy(file = @file)
      FileUtils.rm file if File.exists? file
      !File.exists? file
    end
    
    # Test object equality
    # - Class#eql? is not being passed to the delegate
    # - it needs a little help
    def eql?(obj)
      if obj.is_a?(self.class)
        return self.record.eql?(obj.record)
      end
      false
    end
    alias equal? eql?
    
    # Diff two records
    # - of limited value except for debugging
    # - output is not very coherent
    def diff(other)
      this = self.record
      other = other.record
      (this.keys + other.keys).uniq.inject({}) do |memo, key|
        unless this[key] == other[key]
          if this[key].kind_of?(Hash) &&  other[key].kind_of?(Hash)
            memo[key] = this[key].diff(other[key])
          else
            memo[key] = [this[key], other[key]] 
          end
        end
        memo
      end
    end
    
    # Override the Hash getter method
    # - so that we can use Symbols as well as Strings
    def [](key)
      key = key.to_s if key.is_a?(Symbol)
      super(key)
    end
    
    # Override the Hash setter method
    # - so that we can use Symbols as well as Strings
    def []=(key, value)
      key = key.to_s if key.is_a?(Symbol)
      super(key, value)
    end
    
    private
    
    # Synthesize a record
    # - returns a composite record (Hash) compiled by merging the input data with a pre-existing matched record
    # - if there is no matching record, missing attributes will be synthesized from defaults
    # - returns an Hash stored in an instance variable: @composite
    def synthesize(data)
      @real ||= load_plist(@file)
      if @real
        @composite = @real.dup
        @composite.merge!(data)
      else
        @composite = defaults(data)
      end
      @composite
    end
    
    # Handle required but unspecified record attributes
    # - GUID is the only attribute common to all record types
    def defaults(data)
      next_guid = UUID.new
      defaults = { 'generateduid' => ["#{next_guid}"] }
      defaults.merge(data)
    end
    
    # Format the user input so it can be processed
    # - input is key/value pairs
    # - keys are preserved
    # - values are converted to arrays to satisfy record schema
    def normalize(input)
      name_error = "Name attribute only supports lowercase letters, hypens, and underscrores."
      # If there's only a single arg, and it's a String, make it the :name attrib
      input  = input.is_a?(String) ? { 'name' => input } : input
      result = input.inject({}){ |memo,(k,v)| memo[k.to_s] = [v.to_s]; memo }
      raise DSLocalError.new(name_error) unless result['name'].first.match /^[a-z0-9][a-z0-9_-]*$/
      result
    end
    
    # Returns the type of record being instantiated
    # - derived from class of object
    # - returns String 
    def record_type
      string = self.class.to_s
      parts = string.split(/::/)
      parts.last.to_s.downcase
    end
    
    # Get all records of type
    # - returns Array of all records for the matching type
    def all_records(node)
      records = []
      search_base = "#{DSLOCAL_ROOT}/#{node}/#{@record_type + 's'}"
      files = Dir["#{search_base}/*.plist"]
      unless files.empty?
        files.each do |path|
          records << eval("#{self.class}.init_with_file('#{path}')")
        end
      end
      records
    end
    
    # For a set of records, get all attributes of type
    # - params are: type (Symbol) and records (Array)
    # - symbol is one of the valid DSLocalRecord attribute types (ie. :uid, :gid) as Symbol
    # - array is a collection of records (see DSLocalRecord#all_records)
    # - parses array of records and collects attribs of type
    # - returns Array
    def get_all_attribs_of_type(type, records)
      type = type.to_s
      begin
        attribs = []
        unless records.empty?
          records.each do |record|
            attrib = record[type]
            next if attrib.empty?
            attribs << attrib
          end
        end
      rescue => error
        puts "Ruby Error: #{error.message}"
      end
      attribs
    end
    
    # Given an array of id number attributes, find the next available id number
    # - params are: min (Integer) and ids (Array)
    # - scans the array and delivers the next free id number
    # - returns String
    def next_id(min, ids)
      ids.flatten!
      ids.collect! { |id| id.to_i }
      begin
        ids.sort!.uniq!
        ids.each_with_index do |id, i|
          next if (id < min)
          next if (id + 1 == ids[i + 1])
          return (id + 1).to_s
        end
      rescue => error
        puts "Ruby Error: #{error.message}"
      end
      min.to_s
    end
    
    # Provide dot notation for setting and getting valid attribs
    def method_missing(meth, *args, &block)
      if args.empty?
        return self[meth.to_s] if self[meth.to_s]
        return nil if defaults(@data)[meth.to_s]
      else
        if meth.to_s =~ /=$/
          if self["#{$`}"] or defaults(@data)["#{$`}"]
            if args.is_a? Array
              return self["#{$`}"] = (args.each { |e| e.to_s }).flatten
            elsif args.is_a? String
              return self["#{$`}"] = e.to_s
            end
          end
        end
      end
      super
    end
    
  end
  
end

