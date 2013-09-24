module MacAdmin
  
  # MCX
  # - methods and classes mixed into MacAdmin::DSLocalRecord for managing MCX policy 
  module MCX
    
    # Policy
    # - document format for mcx_export
    class Policy
      
      MANIFESTS = '/System/Library/CoreServices/ManagedClient.app/Contents/Resources'
      
      def initialize(mcx_settings)
        @documents = mcx_settings
        @policy = process_documents(@documents)
      end
      
      # Dump the document in a human-readable format
      def to_plist
        @policy.to_plist({:plist_format => CFPropertyList::List::FORMAT_XML, :formatted => true})
      end
      
      private
      
      # Process each of the domain documents 
      def process_documents(documents)
        documents.inject({}) do |dict, doc|
          plist = CFPropertyList::List.new(:data => doc)
          native = CFPropertyList.native_types(plist.value)
          native['mcx_application_data'].inject({}) do |result, (domain, domain_dict)|
            dict[domain] = process_domain(domain, domain_dict)
            dict
          end
        end
      end
      
      # Process the domain preference document
      # - flattens and reformats the domain document into constituent keys
      def process_domain(domain, domain_dict)
        manifest = "#{MANIFESTS}/#{domain}.manifest/Contents/Resources/#{domain}.manifest"
        upk_subkeys = load_upk_subkeys(manifest)
        domain_dict.inject({}) do |result, (enforcement, enforcement_array)|
          enforcement_array.inject({}) do |hash, dict|
            state = dict.include?('mcx_data_timestamp') ? 'once' : 'often'
            state = 'always' if enforcement.eql? 'Forced'
            dict['mcx_preference_settings'].each do |name, value|
              result[name] = { 'state' => state, 'value' => value }
              if upk_subkeys
                upk = get_upk_info(name, state, upk_subkeys)
                result[name]['upk'] = get_upk_info(name, state, upk_subkeys) if upk
              end
              result
            end
          end
          result
        end
      end
      
      # Load the domain's preference manifest and return the UPK subkeys
      # - returns Array
      def load_upk_subkeys(manifest)
        upk_subkeys = []
        if File.exists? manifest
          plist = CFPropertyList::List.new(:file => manifest)
          native = CFPropertyList.native_types(plist.value)
          upk_subkeys = native['pfm_subkeys'].select do |dict|
            if dict['pfm_type'].eql? 'union policy'
              dict
            end
          end
        end
        upk_subkeys
      end
      
      # Determine the most appropriate UPK keys for the given preference
      # - returns Hash
      def get_upk_info(name, state, upk_subkeys)
        info = nil
        if upk_subkeys
          results = upk_subkeys.inject({}) do |results, dict|
            if dict['pfm_upk_input_keys'].include? name
              results[dict['pfm_upk_output_name']] = dict
            end
            results
          end
          if results
            if results.size > 1
              if state.eql? 'always'
                results = results.select { |k,v| v if k =~ /-managed\z/ }
                info = results.flatten.last
              else
                results = results.select { |k,v| v if k =~ /\Auser\z/ }
                info = results.flatten.last
              end
            else
              info = results.first
            end
          end
        end
        if info
          upk = { 'mcx_input_key_names' => info['pfm_upk_input_keys'],
            'mcx_output_key_name' => info['pfm_upk_output_name'],
            'mcx_remove_duplicates' => info['pfm_remove_duplicates']
          }
          return upk
        end
        nil
      end
      
    end
    
    # EmbeddedDocument
    # - domain level MCX document suitable for storage in the record's mcx_settings array
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
    
    # Settings
    # - class representing the structure of the mcx_settings array
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
          @domains << doc.formatted
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
    
    # Export the MCX preferences for the record
    def mcx_export
      doc = Policy.new self['mcx_settings']
      doc.to_plist
    end
    
    # Show the raw content of the mcx_settings array
    def mcx_settings
      self['mcx_settings']
    end
    
    # Pretty print the contents of the record's mcx_settings array
    def pretty_mcx
      self['mcx_settings'].collect { |doc| CGI.unescapeHTML doc }
    end
    
    # Does the object have any MCX policy?
    def has_mcx?
      self.has_key? 'mcx_settings' and self['mcx_settings'].is_a? Array and not self['mcx_settings'].empty?
    end
    
    # Remove all MCX policy from the object
    def mcx_delete
      self.delete('mcx_flags')
      self.delete('mcx_settings')
    end
    
  end
  
end