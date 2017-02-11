ActiveRecord::Base.configurations = {
  'test' => {
    'adapter' =>  'sqlite3',
    'timeout' =>  500,
    'database' => ':memory:'
  }
}

ActiveRecord::Base.establish_connection(:test)
