module Zapata
  RETURN_TYPES = %i(arg optarg sym float str int ivar lvar true false)
  DIVE_TYPES = %i(begin block defined? nth_ref splat kwsplat class
    block_pass sclass masgn or and irange erange when and
    return array kwbegin yield while dstr ensure pair)
  ASSIGN_TYPES = %i(ivasgn lvasgn or_asgn casgn)
  DEF_TYPES = %i(def defs)
  HARD_TYPES = %i(dsym resbody mlhs const nil next self false true break zsuper
    super retry rescue match_with_lvasgn case op_asgn regopt regexp)
  TYPES_BY_SEARCH_FOR = {
    klass: %i(class),
    var: ASSIGN_TYPES,
    def: DEF_TYPES,
    send: %i(send),
  }

  PRIMITIVE_TYPES = {
    Basic: RETURN_TYPES,
    Var: ASSIGN_TYPES,
    Def: DEF_TYPES,
    Send: %i(send),
    Array: %i(args array),
    Hash: %i(hash),
    Ivar: %i(ivar),
    Klass: %i(class),
    Const: %i(const),
  }.freeze

  class Diver
    class << self
      def search_for(what)
        @search_for = what
      end

      def dive(code)
        return Primitive::Raw.new(:nil, nil) unless code

        current_type = code.type
        subklass_pair = PRIMITIVE_TYPES.detect do |_, types|
          types.include?(current_type)
        end

        if subklass_pair
          klass = "Zapata::Primitive::#{subklass_pair.first}".constantize
          result = klass.new(code)

          DB.create(result) if search_for_types.include?(current_type)
        end

        deeper_dives(code) if DIVE_TYPES.include?(current_type)
        result
      end

      def search_for_types
        TYPES_BY_SEARCH_FOR[@search_for]
      end

      def deeper_dives(code)
        code.to_a.each do |part|
          if part
            dive(part)
          else
            { type: :error, code: part }
          end
        end
      end
    end
  end
end
