class Hash
  # Recursively convert the keys. Example:
  # irb> {:bla_bla => 1, "wow_now" => {:look_ma => true}}.convert_keys{|k| k.camelize} 
  # irb> => {:BlaBla => 1, "WowNow" => {:LookMa => true}}
  def convert_keys(&block)
    block_given? ? self.inject({}) do |h,(k,v)|
      h[k.is_a?(Symbol) ? yield(k.to_s).to_sym : yield(k.to_s)] = v.respond_to?('convert_keys') ? v.convert_keys(&block) : v
      h
    end : self
  end
  
  # First camelizes the keys, then convert the whole hash to JSON
  def to_js
    self.delete_if{ |k,v| v == 'null' } # we don't need to explicitely pass null values to javascript
    self.convert_keys{|k| k.camelize(:lower)}.to_json
  end

  # Converts values to strings
  def values_to_s
    self.each_pair{|k,v| self[k] = v.to_s if v.is_a?(Symbol)}
  end
  
end

class Array
  # Camelizes the keys of hashes and converts them to JSON (non-recursive)
  def to_js
    self.map{|el| el.is_a?(Hash) ? el.convert_keys{|k| k.camelize(:lower)} : el}.to_json
  end
  
  # Applies convert_keys to each element which responds to convert_keys
  def convert_keys(&block)
    block_given? ? self.map do |i|
      i.respond_to?('convert_keys') ? i.convert_keys(&block) : i
    end : self
  end
end

class String
  # Converts self to "literal JSON"-string - one that doesn't get quotes appended when being sent "to_json" method
  def l
    def self.to_json
      self
    end
    self
  end
  
  def to_js
    self.camelize(:lower)
  end
end

class Symbol
  def to_js
    self.to_s.camelize(:lower).to_sym
  end
end