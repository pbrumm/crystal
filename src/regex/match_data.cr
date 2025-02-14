class Regex
  # `Regex::MatchData` is the type of the special variable `$~`, and is the type
  # returned by `Regex#match` and `String#match`. It encapsulates all the
  # results of a regular expression match.
  #
  # ```
  # if md = "Crystal".match(/[p-s]/)
  #   md.string # => "Crystal"
  #   md[0]     # => "r"
  #   md[1]?    # => nil
  # end
  # ```
  #
  # Many `Regex::MatchData` methods deal with capture groups, and accept an integer
  # argument to select the desired capture group. Capture groups are numbered
  # starting from `1`, so that `0` can be used to refer to the entire regular
  # expression without needing to capture it explicitly.
  struct MatchData
    # Returns the original regular expression.
    #
    # ```
    # "Crystal".match(/[p-s]/).not_nil!.regex # => /[p-s]/
    # ```
    getter regex : Regex

    # Returns the number of capture groups, including named capture groups.
    #
    # ```
    # "Crystal".match(/[p-s]/).not_nil!.group_size          # => 0
    # "Crystal".match(/r(ys)/).not_nil!.group_size          # => 1
    # "Crystal".match(/r(ys)(?<ok>ta)/).not_nil!.group_size # => 2
    # ```
    getter group_size : Int32

    # Returns the original string.
    #
    # ```
    # "Crystal".match(/[p-s]/).not_nil!.string # => "Crystal"
    # ```
    getter string : String

    # :nodoc:
    def initialize(@regex : Regex, @code : LibPCRE::Pcre, @string : String, @pos : Int32, @ovector : Int32*, @group_size : Int32)
    end

    # Returns the number of elements in this match object.
    #
    # ```
    # "Crystal".match(/[p-s]/).not_nil!.size          # => 1
    # "Crystal".match(/r(ys)/).not_nil!.size          # => 2
    # "Crystal".match(/r(ys)(?<ok>ta)/).not_nil!.size # => 3
    # ```
    def size : Int32
      group_size + 1
    end

    # Returns the position of the first character of the *n*th match.
    #
    # When *n* is `0` or not given, uses the match of the entire `Regex`.
    # Otherwise, uses the match of the *n*th capture group.
    #
    # Raises `IndexError` if the index is out of range or the respective
    # subpattern is unused.
    #
    # ```
    # "Crystal".match(/r/).not_nil!.begin(0)     # => 1
    # "Crystal".match(/r(ys)/).not_nil!.begin(1) # => 2
    # "クリスタル".match(/リ(ス)/).not_nil!.begin(0)    # => 1
    # "Crystal".match(/r/).not_nil!.begin(1)     # IndexError: Invalid capture group index: 1
    # "Crystal".match(/r(x)?/).not_nil!.begin(1) # IndexError: Capture group 1 was not matched
    # ```
    def begin(n = 0) : Int32
      @string.byte_index_to_char_index(byte_begin(n)).not_nil!
    end

    # Returns the position of the next character after the match.
    #
    # When *n* is `0` or not given, uses the match of the entire `Regex`.
    # Otherwise, uses the match of the *n*th capture group.
    #
    # Raises `IndexError` if the index is out of range or the respective
    # subpattern is unused.
    #
    # ```
    # "Crystal".match(/r/).not_nil!.end(0)     # => 2
    # "Crystal".match(/r(ys)/).not_nil!.end(1) # => 4
    # "クリスタル".match(/リ(ス)/).not_nil!.end(0)    # => 3
    # "Crystal".match(/r/).not_nil!.end(1)     # IndexError: Invalid capture group index: 1
    # "Crystal".match(/r(x)?/).not_nil!.end(1) # IndexError: Capture group 1 was not matched
    # ```
    def end(n = 0) : Int32
      @string.byte_index_to_char_index(byte_end(n)).not_nil!
    end

    # Returns the position of the first byte of the *n*th match.
    #
    # When *n* is `0` or not given, uses the match of the entire `Regex`.
    # Otherwise, uses the match of the *n*th capture group.
    #
    # Raises `IndexError` if the index is out of range or the respective
    # subpattern is unused.
    #
    # ```
    # "Crystal".match(/r/).not_nil!.byte_begin(0)     # => 1
    # "Crystal".match(/r(ys)/).not_nil!.byte_begin(1) # => 2
    # "クリスタル".match(/リ(ス)/).not_nil!.byte_begin(0)    # => 3
    # "Crystal".match(/r/).not_nil!.byte_begin(1)     # IndexError: Invalid capture group index: 1
    # "Crystal".match(/r(x)?/).not_nil!.byte_begin(1) # IndexError: Capture group 1 was not matched
    # ```
    def byte_begin(n = 0) : Int32
      check_index_out_of_bounds n
      n += size if n < 0
      value = @ovector[n * 2]
      raise_capture_group_was_not_matched(n) if value < 0
      value
    end

    # Returns the position of the next byte after the match.
    #
    # When *n* is `0` or not given, uses the match of the entire `Regex`.
    # Otherwise, uses the match of the *n*th capture group.
    #
    # Raises `IndexError` if the index is out of range or the respective
    # subpattern is unused.
    #
    # ```
    # "Crystal".match(/r/).not_nil!.byte_end(0)     # => 2
    # "Crystal".match(/r(ys)/).not_nil!.byte_end(1) # => 4
    # "クリスタル".match(/リ(ス)/).not_nil!.byte_end(0)    # => 9
    # "Crystal".match(/r/).not_nil!.byte_end(1)     # IndexError: Invalid capture group index: 1
    # "Crystal".match(/r(x)?/).not_nil!.byte_end(1) # IndexError: Capture group 1 was not matched
    # ```
    def byte_end(n = 0) : Int32
      check_index_out_of_bounds n
      n += size if n < 0
      value = @ovector[n * 2 + 1]
      raise_capture_group_was_not_matched(n) if value < 0
      value
    end

    # Returns the match of the *n*th capture group, or `nil` if there isn't
    # an *n*th capture group.
    #
    # When *n* is `0`, returns the match for the entire `Regex`.
    #
    # ```
    # "Crystal".match(/r(ys)/).not_nil![0]? # => "rys"
    # "Crystal".match(/r(ys)/).not_nil![1]? # => "ys"
    # "Crystal".match(/r(ys)/).not_nil![2]? # => nil
    # ```
    def []?(n : Int) : String?
      return unless valid_group?(n)

      n += size if n < 0
      start = @ovector[n * 2]
      finish = @ovector[n * 2 + 1]
      return if start < 0
      @string.byte_slice(start, finish - start)
    end

    # Returns the match of the *n*th capture group, or raises an `IndexError`
    # if there is no *n*th capture group.
    #
    # ```
    # "Crystal".match(/r(ys)/).not_nil![1] # => "ys"
    # "Crystal".match(/r(ys)/).not_nil![2] # raises IndexError
    # ```
    def [](n : Int) : String
      check_index_out_of_bounds n
      n += size if n < 0

      value = self[n]?
      raise_capture_group_was_not_matched n if value.nil?
      value
    end

    # Returns the match of the capture group named by *group_name*, or
    # `nil` if there is no such named capture group.
    #
    # ```
    # "Crystal".match(/r(?<ok>ys)/).not_nil!["ok"]? # => "ys"
    # "Crystal".match(/r(?<ok>ys)/).not_nil!["ng"]? # => nil
    # ```
    #
    # When there are capture groups having same name, it returns the last
    # matched capture group.
    #
    # ```
    # "Crystal".match(/(?<ok>Cr).*(?<ok>al)/).not_nil!["ok"]? # => "al"
    # ```
    def []?(group_name : String) : String?
      max_start = -1
      match = nil
      named_capture_number(group_name) do |n|
        start = @ovector[n * 2]
        if start > max_start
          max_start = start
          match = self[n]?
        end
      end
      match
    end

    # Returns the match of the capture group named by *group_name*, or
    # raises an `KeyError` if there is no such named capture group.
    #
    # ```
    # "Crystal".match(/r(?<ok>ys)/).not_nil!["ok"] # => "ys"
    # "Crystal".match(/r(?<ok>ys)/).not_nil!["ng"] # raises KeyError
    # ```
    #
    # When there are capture groups having same name, it returns the last
    # matched capture group.
    #
    # ```
    # "Crystal".match(/(?<ok>Cr).*(?<ok>al)/).not_nil!["ok"] # => "al"
    # ```
    def [](group_name : String) : String
      match = self[group_name]?
      unless match
        named_capture_number(group_name) do
          raise KeyError.new("Capture group '#{group_name}' was not matched")
        end
        raise KeyError.new("Capture group '#{group_name}' does not exist")
      end
      match
    end

    # Returns all matches that are within the given range.
    def [](range : Range) : Array(String)
      self[*Indexable.range_to_index_and_count(range, size) || raise IndexError.new]
    end

    # Like `#[](Range)`, but returns `nil` if the range's start is out of range.
    def []?(range : Range) : Array(String)?
      self[*Indexable.range_to_index_and_count(range, size) || raise IndexError.new]?
    end

    # Returns count or less (if there aren't enough) matches starting at the
    # given start index.
    def [](start : Int, count : Int) : Array(String)
      self[start, count]? || raise IndexError.new
    end

    # Like `#[](Int, Int)` but returns `nil` if the *start* index is out of range.
    def []?(start : Int, count : Int) : Array(String)?
      start, count = Indexable.normalize_start_and_count(start, count, size) { return nil }

      Array(String).new(count) { |i| self[start + i] }
    end

    private def named_capture_number(group_name)
      name_entry_size = LibPCRE.get_stringtable_entries(@code, group_name, out first, out last)
      return if name_entry_size < 0

      while first <= last
        capture_number = (first[0].to_u16 << 8) | first[1].to_u16
        yield capture_number

        first += name_entry_size
      end

      nil
    end

    # Returns the part of the original string before the match. If the match
    # starts at the start of the string, returns the empty string.
    #
    # ```
    # "Crystal".match(/yst/).not_nil!.pre_match # => "Cr"
    # ```
    def pre_match : String
      @string.byte_slice(0, byte_begin(0))
    end

    # Returns the part of the original string after the match. If the match ends
    # at the end of the string, returns the empty string.
    #
    # ```
    # "Crystal".match(/yst/).not_nil!.post_match # => "al"
    # ```
    def post_match : String
      @string.byte_slice(byte_end(0))
    end

    # Returns an array of unnamed capture groups.
    #
    # It is a difference from `to_a` that the result array does not contain the match for the entire `Regex` (`self[0]`).
    #
    # ```
    # match = "Crystal".match(/(Cr)(?<name1>y)(st)(?<name2>al)/).not_nil!
    # match.captures # => ["Cr", "st"]
    #
    # # When this regex has an optional group, result array may contain
    # # a `nil` if this group is not matched.
    # match = "Crystal".match(/(Cr)(stal)?/).not_nil!
    # match.captures # => ["Cr", nil]
    # ```
    def captures : Array(String?)
      name_table = @regex.name_table

      caps = [] of String?
      (1...size).each do |i|
        caps << self[i]? unless name_table.has_key? i
      end

      caps
    end

    # Returns a hash of named capture groups.
    #
    # ```
    # match = "Crystal".match(/(Cr)(?<name1>y)(st)(?<name2>al)/).not_nil!
    # match.named_captures # => {"name1" => "y", "name2" => "al"}
    #
    # # When this regex has an optional group, result hash may contain
    # # a `nil` if this group is not matched.
    # match = "Crystal".match(/(?<name1>Cr)(?<name2>stal)?/).not_nil!
    # match.named_captures # => {"name1" => "Cr", "name2" => nil}
    # ```
    def named_captures : Hash(String, String?)
      name_table = @regex.name_table

      caps = {} of String => String?
      (1...size).each do |i|
        if (name = name_table[i]?) && !caps.has_key?(name)
          caps[name] = self[name]?
        end
      end

      caps
    end

    # Convert this match data into an array.
    #
    # ```
    # match = "Crystal".match(/(Cr)(?<name1>y)(st)(?<name2>al)/).not_nil!
    # match.to_a # => ["Crystal", "Cr", "y", "st", "al"]
    #
    # # When this regex has an optional group, result array may contain
    # # a `nil` if this group is not matched.
    # match = "Crystal".match(/(Cr)(?<name1>stal)?/).not_nil!
    # match.to_a # => ["Cr", "Cr", nil]
    # ```
    def to_a : Array(String?)
      (0...size).map { |i| self[i]? }
    end

    # Convert this match data into a hash.
    #
    # ```
    # match = "Crystal".match(/(Cr)(?<name1>y)(st)(?<name2>al)/).not_nil!
    # match.to_h # => {0 => "Crystal", 1 => "Cr", "name1" => "y", 3 => "st", "name2" => "al"}
    #
    # # When this regex has an optional group, result array may contain
    # # a `nil` if this group is not matched.
    # match = "Crystal".match(/(Cr)(?<name1>stal)?/).not_nil!
    # match.to_h # => {0 => "Cr", 1 => "Cr", "name1" => nil}
    # ```
    def to_h : Hash(Int32 | String, String?)
      name_table = @regex.name_table

      hash = {} of (String | Int32) => String?
      (0...size).each do |i|
        if name = name_table[i]?
          hash[name] = self[name]? unless hash.has_key?(name)
        else
          hash[i] = self[i]?
        end
      end

      hash
    end

    def inspect(io : IO) : Nil
      to_s(io)
    end

    def to_s(io : IO) : Nil
      name_table = @regex.name_table

      io << "Regex::MatchData("
      size.times do |i|
        io << ' ' << name_table.fetch(i, i) << ':' if i > 0
        self[i]?.inspect(io)
      end
      io << ')'
    end

    def pretty_print(pp) : Nil
      name_table = @regex.name_table

      pp.surround("Regex::MatchData(", ")", left_break: nil, right_break: nil) do
        size.times do |i|
          pp.breakable if i > 0
          pp.group do
            if i == 0
              self[i].pretty_print pp
            else
              pp.text "#{name_table.fetch(i, i)}:"
              pp.nest do
                pp.breakable ""
                self[i]?.pretty_print pp
              end
            end
          end
        end
      end
    end

    def dup
      self
    end

    def clone
      self
    end

    def ==(other : Regex::MatchData)
      return false unless size == other.size
      return false unless regex == other.regex
      return false unless string == other.string

      @ovector.memcmp(other.@ovector, size * 2) == 0
    end

    # See `Object#hash(hasher)`
    def hash(hasher)
      hasher = regex.hash hasher
      hasher = string.hash hasher
      Slice.new(@ovector, size * 2).hash(hasher)
    end

    private def check_index_out_of_bounds(index)
      raise_invalid_group_index(index) unless valid_group?(index)
    end

    private def valid_group?(index)
      -size <= index < size
    end

    private def raise_invalid_group_index(index)
      raise IndexError.new("Invalid capture group index: #{index}")
    end

    private def raise_capture_group_was_not_matched(index)
      raise IndexError.new("Capture group #{index} was not matched")
    end
  end
end
