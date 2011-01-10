module MassiveRecord
  module ORM
    module Schema
      class Field
        include ActiveModel::Validations

        TYPES = [:string, :integer, :float, :boolean, :array, :hash, :date, :time]

        attr_writer :default
        attr_accessor :name, :column, :type, :fields


        validates_presence_of :name
        validates_inclusion_of :type, :in => TYPES
        validate do
          errors.add(:fields, :blank) if fields.nil?
          errors.add(:name, :taken) if fields.try(:attribute_name_taken?, name)
        end

      
        #
        # Creates a new field based on arguments from DSL
        # args: name, type, options
        #
        def self.new_with_arguments_from_dsl(*args)
          field_options = args.extract_options!
          field_options[:name] = args[0]
          field_options[:type] = args[1]

          new(field_options)
        end



        def initialize(*args)
          options = args.extract_options!.to_options

          self.fields = options[:fields]
          self.name = options[:name]
          self.column = options[:column]
          self.type = options[:type] || :string
          self.default = options[:default]
        end


        def ==(other)
          other.instance_of?(self.class) && other.hash == hash
        end
        alias_method :eql?, :==

        def hash
          name.hash
        end

        def type=(type)
          @type = type.to_sym
        end


        def column
          @column || name
        end

        def default
          @default.duplicable? ? @default.dup : @default
        end

        
        def unique_name
          raise "Can't generate a unique name as I don't have a column family!" if column_family.nil?
          [column_family.name, column].join(":")
        end

        def column_family
          fields.try :contained_in
        end

        def column=(column)
          column = column.to_s unless column.nil?
          @column = column
        end




        def decode(value)
          return nil if value.nil?

          if type == :boolean
            return value if value === TrueClass || value === FalseClass
          else
            return value if value.class == type.to_s.classify.constantize
          end
          
          case type
          when :string
            value
          when :boolean
            value.to_s.empty? ? nil : !value.to_s.match(/^(true|1)$/i).nil?
          when :integer
            value.to_s.empty? ? nil : value.to_i
          when :float
            value.to_s.empty? ? nil : value.to_f
          when :date
            value.empty? ? nil : Date.parse(value)
          when :time
            value.empty? ? nil : Time.parse(value)
          when :array
            value
          when :hash
            value
          else
            value
          end
        end



        private

        def name=(name)
          @name = name.to_s
        end
      end
    end
  end
end