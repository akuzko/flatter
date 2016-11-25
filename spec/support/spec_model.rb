def SpecModel(table_name, setup, &block)
  ::ActiveRecord::Base.connection.create_table(table_name) do |t|
    setup.each do |column_name, type|
      null = true
      if type.to_s.ends_with? ?!
        type = type.to_s[0...-1]
        null = false
      end
      t.column column_name, type, null: null
    end

    t.timestamps null: true
  end

  Class.new(::ActiveRecord::Base, &block).tap do |klass|
    klass.instance_variable_set '@table_name', table_name
  end
end
