# Flatter

[![Build Status](https://secure.travis-ci.org/akuzko/flatter.png)](http://travis-ci.org/akuzko/flatter)

This gem supersedes [FlatMap](https://github.com/TMXCredit/flat_map) gem. With
only it's core concepts in mind it has been written from complete scratch to
provide more pure, clean, extensible code and reliable functionality.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flatter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flatter

## Usage

If you happen to use `FlatMap` gem , check out
[Flatter and FlatMap: What's Changed](https://github.com/akuzko/flatter/wiki/Flatter-and-FlatMap:-What's-Changed) wiki page.

Flatter's main working units are instances of `Mapper` class. **Mappers** are essentially
wrappers around your related ActiveModel-like models, map their attributes to mapper's
accessors via **mappings**, can be *mounted* by other mappers, and can define flexible
behavior via **traits**. Let's cover this topics one by one.

### Mappings

Mappings represent a mapper's property, which is usually maps to some attribute of the
target object. Since eventually mappers are used in combination with each other, it is
better to map model's attribute with a "full name" to avoid collisions, for example:

```ruby
# models:
class Person
  include ActiveModel::Model

  attr_accessor :first_name, :last_name
end

class Group
  include ActiveModel::Model

  attr_accessor :name
end

class Department
  include ActiveModel::Model

  attr_accessor :name
end

# mappers:
class PersonMapper < Flatter::Mapper
  map :first_name, :last_name
  # ^- it's ok, since :first_name and :last_name attributes are
  # not likely to be used somewhere else
end

class GroupMapper < Flatter::Mapper
  map group_name: :name
  # ^- maps mapper's :group_name attribute to target's :name attribute
end

class DepartmentMapper < Flatter::Mapper
  map department_name: :name
  # ^- maps mapper's :department_name attribute to target's :name attribute
end
```

#### Mapping Options

- `:reader` Allows to add a custom logic for reading target's attribute.
  When value is `String` or `Symbol`, calls a method defined by a **mapper** class.
  If that method accepts an argument, mapping name will be passed to it.
  When value is `Proc`, it is executed in context of mapper object, yielding
  mapping name if block has arity of 1. For other arbitrary objects will simply
  return that object.
- `:writer` Allows to control a way how value is assigned (written).
  When value is `String` or `Symbol`, calls a method defined by a **mapper** class,
  passing a value to it. If that method accepts second argument, mapping name will be
  additionally passed to it.
  When value is `Proc`, it is executed in context of mapper object, yielding
  value and optionally mapping name if block has arity of 2. For other values will
  raise error.

### Mountings

Stand-alone mappers provide not very much benefit. However, mappers have a powerful
ability to be mounted on top of each other. When mapper mounts another one, it
gains access to all of it's mappings, and they become accessible in a plain way.

For example, having `Person`, `Department` and `Group` classes defined above with
additional sample relationship we might have:

```ruby
# models:
class Person
  def department
    @department ||= Department.new(name: 'Default')
  end

  def group
    @group ||= Group.new(name: 'General')
  end
end

# mappers:
class PersonMapper < Flatter::Mapper
  map :first_name, :last_name

  mount :department
  mount :group
end

person = Person.new(first_name: 'John', last_name: 'Smith')
mapper = PersonMapper.new(person)

mapper.read # => {
  # 'first_name'      => 'John',
  # 'last_name'       => 'Smith',
  # 'department_name' => 'Default',
  # 'group_name'      => 'General' }

mapper.group_name = 'Managers'
person.group.name # => "Managers"
```

#### Mounting Options

- `:mapper_class_name` Name of the mapper class (`String`) if it cannot be
  determined from the mounting name itself. By default it is camelized name
  followed by 'Mapper', for example, for `:group` mounting, default mapper
  class name is `'GroupMapper'`.
- `:mapper_class` Used mostly internally, but allows to specify mapper class
  itself. Has more priority than `:mapper_class_name` option.
- `:target` Allows to manually set mounted mapper's target. By default target is
  obtained from mounting mapper's target by sending it mounting name. In example
  above target for `:group` mapping was obtained by sending `:group` method to
  `person` object, which was the target of root mapper.
  When value is `String` or `Symbol`, it is considered as a method name of the
  **mapper**, which is called with no arguments.
  When value is `Proc`, it is called yielding mapper's target to it.
  For other objects, objects themselves are used as targets.
- `:traits` Allows to specify a list of traits to be applied for mounted mappers.
  See **Traits** section bellow.

### Callbacks

Mappers include `ActiveModel::Validation` module and thus support `ActiveSupport`'s
callbacks. Additionally, `:save` callbacks have been defined for `Flatter::Mapper`,
so you can do something like `set_callback :save, :after, :send_invitation`.

### Traits

Traits are another powerful mapper ability. Traits allow to encapsulate named sets
of additional definitions, and optionally use them on mapper initialization or
when mounting mapper in other one. Everything that can be defined within the mapper
can be defined withing the trait. For example (suppose we have some additional
`:with_counts` trait defined on `DepartmentMapper` alongside with model relationships):

```ruby
class Person < Flatter::Mapper
  map :first_name, :last_name

  trait :full_info do
    map :middle_name, dob: :date_of_birth

    mount :group
  end

  trait :with_department do
    mount :department, traits: :with_counts
  end
end

mapper = PersonMapper.new(person)
full_mapper = PersonMapper.new(person, :full_info, :with_department)

mapper.read # => {
  # 'first_name'      => 'John',
  # 'last_name'       => 'Smith' }

full_mapper.read # => {
  # 'first_name'              => 'John',
  # 'last_name'               => 'Smith',
  # 'middle_name'             => nil,
  # 'dob'                     => Wed, 18 Feb 1981,
  # 'group_name'              => 'General'
  # 'department_name'         => 'Default',
  # 'department_people_count' => 31 }
```

#### Traits and callbacks

Since traits are internally mappers (which allows you to define everything mapper
can), you can also define callbacks on traits, allowing you to dynamically opt-in,
opt-out and reuse functionality. Keep in mind that `ActiveModel`'s validation
routines are also just a set of callbacks, meaning that you can define sets of
validation in traits, mix them together in any way. For example:

```ruby
class PersonMapper < Flatter::Mapper
  map :first_name, :last_name

  trait :registration do
    map personal_email: :email

    validates_presence_of :first_name, :last_name
    validates :personal_email, :presence: true, email: true

    set_callback :save, :after, :send_greeting

    def send_greeting
      PersonMailer.greeting(self).deliver_now
    end
  end
end
```

#### Traits and shared methods

Despite the fact traits are separate objects, you can call methods defined in
one trait from another trait, as well as methods defined in root mapper itself
(such as attribute methods). That allows you to treat traits as parts of the
root mapper itself.

#### Inline extension traits

When initializing a mapper, or defining a mounting, you can pass a block with
additional definitions. This block will be treated as an anonymous extension trait.
For example, let's suppose that `email` from example above is actually a part
of another `User` model that has it's own `UserMapper` with defined `:email` mounting.
Then we might have something like:

```ruby
class PersonMapper < Flatter::Mapper
  map :first_name, :last_name

  trait :registration do
    validates_presence_of :first_name, :last_name

    mount :user do
      validates :email, :presence: true, email: true
      set_callback :save, :after, :send_greeting

      def send_greeting
        UserMailer.greeting(self).deliver_now
      end
    end
  end
end

```

### Processing Order

`Flatter` mappers have a well-defined processing order of mountings (including
traits), best shown by example. Suppose we have something like (in pseudo code):

```
MapperA
  trait :trait_a1 do
    mount :b, traits: :trait_b do
      # some callbacks defined here
  trait :trait_a2 do
    mount :c
  mount :d
```

Mappers are processed (validated and saved) from top to bottom. Let's have initialized
`a = MapperA.new(a, :trait_a2, :trait_a1)`. Please note traits order, it is very
important: `:trait_a2` goes first, so it's callbacks and mountings will go first too.
So if we call `a.save`, we will have following execution order (suppose, we have
defined callbacks for all traits and mappers):

```
trait_a2.before_save
trait_a1.before_save
A.before_save
A.save
A.after_save
trait_a1.after_save
trait_a2.after_save
C.before_save
C.save
C.after_save
trait_b.before_save
B_extension.before_save
B.before_save
B.save
B.after_save
B_extension.after_save
trait_b.after_save
D.before_save
D.save
D.after_save
```

### Attribute methods

All mappers can access mapped values via attribute methods that match mapping names.
That allows you to easily use mappers for building forms or developing other
functionality.

### Public API

Some methods of the public API that should help you building your mappers:

#### Mapper methods

- `target` - returns mapper's target - an object mapper extracts values from
  and assigns values to using defined mappings.
- `mappings` - returns a plain hash of all the mappings (including ones related
  to mounted mappers) in a form of `{name <String> => mapping object <Mapping>}`
- `mapping(name)` - returns a mapping with a `name` name. The same as `mappings[name.to_s]`
- `mountings` - returns a plain hash of all mounted mappers (including all used traits)
  in a form of `{name <String> => mapper object <Mapper>}`
- `mounting(name)` - returns a mounting with a `name` name. The same as `mountings[name.to_s]`
- `read` - returns a hash of all values obtained by all mappings in a form of
  `{name <String> => value <Object>}`
- `write(params)` - for each defined mapping, including mappings from mounted
  mappers and traits, passes value from params that corresponds to mapping name
  to that mapping's `write` method.
- `valid?` - runs validation routines and returns `true` if there are no errors.
- `errors` - returns mapper's `Errors` object
- `save` - runs save routines. If target object responds to `save` method, will
  call it and return it's value. Returns true otherwise. If multiple mappers
  are mounted, returns `true` only if all mounted mappers returned `true` on saving
  their targets.
- `apply(params)` - writes `params`, runs validation and runs save routings if
  validation passed.
- `trait?` - returns `true` if `self` is a trait mapper.

#### Mapping methods

- `read` reads value from target according to setup.
- `read!` tries to directly read value from target based on mapping `target_attribute`
  property. Ignores `:reader` option.
- `write(value)` assigns a `value` to target according to setup.
- `write!(value)` tries to directly assign a value to target based on mapping
  `target_attribute` property. Ignores `:writer` option.

### Extensions

Aside from core functionality and behavior defined in this gem, there is also
[flatter-extensions](https://github.com/akuzko/flatter-extensions) gem that
provides extensions to help you use mappers more efficiently. At this point there
are following extensions:

- `:multiparam` Allows you to define multiparam mappings by adding `:multiparam`
  option to mapping. Works pretty much like `Rails` multiparam attribute assignment.
- `:skipping` Allows to skip mappers (mountings) from the processing chain by
  calling `skip!` method on a particular mapper. When used in before validation
  callbacks, for example, allows you to ignore some extra processing.
- `:order` Allows you to manually control processing order of mappers and their
  mountings. Provides `:index` option for mountings, which can be either a Number,
  which means order for both validation and saving routines, or a hash like
  `index: {validate: -1, save: 2}`. By default all mappers have index of `0` and
  processed from top to bottom.
- `:active_record` Very useful extension that allows you to effectively use mappers
  when working with ActiveRecord objects with defined relationships and associations
  that form a structured graph that you want to work with as a plain data structure.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/akuzko/flatter.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

