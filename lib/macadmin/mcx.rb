module MacAdmin
  
  module MCX
    
    class EmbeddedDocument
      
      attr_reader :document
      
      def initialize(domain, content)
        @document = { 'mcx_application_data' => {} }
        @domain  = domain
        @content = process(content)
      end
      
      def formatted
        @document.to_plist({:plist_format => CFPropertyList::List::FORMAT_XML, :formatted => true})
      end
      
      def escaped
        CGI.escapeHTML @document.to_plist({:plist_format => CFPropertyList::List::FORMAT_XML, :formatted => true})
      end
      
      private
      
      def process(content)
        @document['mcx_application_data'][@domain] = {}
        content.each do |pref_name, pref_dict|
          state = pref_dict['state']
          enforcement = (state.eql?('always') ? 'Forced' : 'Set-Once')
          @document['mcx_application_data'][@domain][enforcement] ||= [{}]
          if pref_dict['upk']
            @document['mcx_application_data'][@domain][enforcement][0]['mcx_union_policy_keys'] ||= []
            @document['mcx_application_data'][@domain][enforcement][0]['mcx_union_policy_keys'] << pref_dict['upk']
          end
          @document['mcx_application_data'][@domain][enforcement][0]['mcx_preference_settings'] ||= {}
          @document['mcx_application_data'][@domain][enforcement][0]['mcx_preference_settings'][pref_name] = pref_dict['value']
          if state.eql? 'once'
            @document['mcx_application_data'][@domain][enforcement][0]['mcx_data_timestamp'] = CFPropertyList::CFDate.parse_date(Time.now.utc.xmlschema)
          end
        end
      end
      
    end
    
    class Settings
      
      attr_reader :domains
      
      XML_TAG = '^<\?xml\sversion="1\.0"\sencoding="UTF-8"\?>'
      
      class << self
        def init_with_file(path)
          content = load_plist(path)
          self.new(content)
        end
      end
      
      def initialize(content, type=:data)
        type = :file unless content =~ /#{XML_TAG}/
        plist = CFPropertyList::List.new(type => content)
        native = CFPropertyList.native_types(plist.value)
        @domains = []
        @content = process(native)
      end
      
      private
      
      def process(content)
        content.each do |domain_name, domain_dict|
          doc = EmbeddedDocument.new domain_name, domain_dict
          @domains << doc.escaped
        end
      end
      
    end
    
    # Import MCX Content and apply it to the current object
    # - accepts a single parameter: path to Plist file containing exported MCX policy or a string of XML content representing the MCX policy
    # - re-formats the imported MCX for storage on the record and adds the two require attributes: mcx_flags and mcx_settings
    # - current implmentation replaces policy wholesale (no append)
    def mcx_import(content, append=false)
      settings = Settings.new content
      mcx_flags = { 'has_mcx_settings' => true }
      mcx_flags = mcx_flags.to_plist({:plist_format => CFPropertyList::List::FORMAT_XML, :formatted => true})
      self['mcx_flags'] = [CFPropertyList::Blob.new(mcx_flags)]
      self['mcx_settings'] = settings.domains
    end
    
    def mcx_settings
      self['mcx_settings']
    end
    
    def pretty_mcx
      self['mcx_settings'].collect { |doc| CGI.unescapeHTML doc }
    end
    
    def has_mcx?
      self.has_key? 'mcx_settings' and self['mcx_settings'].is_a? Array and not self['mcx_settings'].empty?
    end
    
    def mcx_delete
      self.delete('mcx_flags')
      self.delete('mcx_settings')
    end
    
  end
  
end