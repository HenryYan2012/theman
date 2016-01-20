module Theman
  class Agency
    class Columns
      attr_accessor :column
      attr_reader :connection

      def initialize(conn)
        @connection = conn
        @columns    = []
      end

      def to_sql #:nodoc:
        @columns.map{|column| column_to_sql(*column)}.join(', ')
      end

      %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |type|
        class_eval <<-EOV, __FILE__, __LINE__ + 1
          def #{type}(name, *args)
            column(name, '#{type}', *args)
          end
        EOV
      end
      
      def symbolize(name) #:nodoc:
        name.is_a?(Symbol) ? name : name.gsub(/ /,"_").gsub(/\W/, "").downcase.to_sym
      end

      def column(name, type, *args) #:nodoc:
        sym_col = symbolize(name)
        @columns.each_with_index do |column, index|
          if column[0] == sym_col
            @columns[index] = [sym_col, type, *args]
            return
          end
        end
        @columns << [sym_col, type, *args]
      end

      def include?(sym_col)
        @columns.map{|column| column[0] }.include?(sym_col)
      end
      
      def column_to_sql(name, type, options = {}) #:nodoc:
        sql = [quote_column_name(name)]
        sql << self.convert_type_to_sql(type, options)

        if options[:null] ==  false
          sql << 'NOT NULL'
        end

        if options[:default]
          sql << "DEFAULT #{options[:default]}"
        end

        sql.join(' ')
      end
      
      def quote_column_name(name) #:nodoc:
        @connection.quote_ident(name.to_s)
      end

      def self.convert_type_to_sql(type, options = {})
        case type
        when 'integer'
          if options[:limit]
            case options[:limit]
            when 1, 2;
              'smallint'
            when 3, 4;
              'integer'
            when 5..8;
              'bigint'
            else
              raise ArgumentError, "No integer type has byte size #{limit}."
            end
          else
            'integer'
          end
        when 'decimal'
          'double precision'
        when 'float'
          'double precision'
        when 'string'
          if options[:limit]
            "character varying(#{options[:limit]})"
          else
            'character varying(255)'
          end
        when 'binary'
          'oid'
        when 'time'
          'time without time zone'
        when 'datetime'
          'timestamp without time zone'
        when 'timestamp'
          'timestamp without time zone'
        else
          type
        end
      end
    end
  end
end
