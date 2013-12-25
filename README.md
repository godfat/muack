# Muack [![Build Status](https://secure.travis-ci.org/godfat/muack.png?branch=master)](http://travis-ci.org/godfat/muack)

by Lin Jen-Shin ([godfat](http://godfat.org))

## LINKS:

* [github](https://github.com/godfat/muack)
* [rubygems](https://rubygems.org/gems/muack)
* [rdoc](http://rdoc.info/github/godfat/muack)

## DESCRIPTION:

Muack -- A fast, small, yet powerful mocking library.

Inspired by [RR][], and it's 32x times faster (750s vs 23s) than RR
for running [Rib][] tests.

[RR]: https://github.com/rr/rr
[Rib]: https://github.com/godfat/rib

## WHY?

Because RR has/had some bugs and it is too complex for me to fix it.
Muack is much simpler and thus much faster and much more consistent.

## REQUIREMENTS:

* Tested with MRI (official CRuby) 2.0.0, 2.1.0, Rubinius and JRuby.

## INSTALLATION:

    gem install muack

## SYNOPSIS:

Here's a quick example using [Bacon][].

``` ruby
require 'bacon'
require 'muack'

include Muack::API

describe 'Hello' do
  before{ Muack.reset  }
  after { Muack.verify }

  should 'say world!' do
    str = 'Hello'
    mock(str).say('!'){ |arg| "World#{arg}" }
    str.say('!').should.equal 'World!'
  end
end
```

[Bacon]: https://github.com/chneukirchen/bacon

### Overview

There are 3 parts in Muack, which are:

* Mocks
* Mocks Modifiers
* Arguments Verifiers (Satisfy)

Mocks are objects with injected methods which we could observe, and mocks
modifiers are telling how we want to observe the mocks, and finally argument
verifiers could help us observe the arguments passed to the injected methods.

Let's explain them one by one.

### Mocks

There are also 3 different kinds of mocks in Muack, which are:

* Mocks
* Stubs
* Spies

You could also think of _mocks_ are _stubs_ + _spies_. Here's the equation:

    mock = stub + spy

Stubs help us inject methods into the objects we want to observe. Spies
help us observe the behaviours of the objects. As for mocks, they inject
methods and observe the behaviours in realtime. They complain immediately
if the behaviours were unexpected. In contrast, if we're not asking spies,
stubs won't complain themselves.

Here's an example using a mock:

``` ruby
obj = Object.new
mock(obj).name{ 'obj' }
p obj.name     # 'obj'
p Muack.verify # true
```

Which is roughly semantically equivalent to using a stub with a spy:

``` ruby
obj = Object.new
stub(obj).name{ 'obj' }
p obj.name     # 'obj'
spy(obj).name
p Muack.verify # true
```

You might wonder, then why mocks or why stubs with spies? The advantage of
using mocks is that, you only need to specify once. I guess this is quite
obvious. However, sometimes we don't care if the injected methods are called
or not, but sometimes we do care. With stubs and spies, we could always put
stubs in the before/setup block, and only when we really care if they are
called or not, we put spies to examine.

On the other hand, stubs aren't limited to testing. If we want to monkey
patching something, stubs could be useful as we don't care how many times
the injected methods are called. Jump to _Muack as a mocky patching library_
section for more detail.

#### Proxy mode

There's

#### any_instance_of mode

### Mocks Modifiers

A modifier is something specifying a property of an injected method.
By making a mock/stub/spy, it would return a modifier descriptor which
we could then specify properties about the injected method.

Note that we could chain properties for a given modifier descriptor
because all public methods for declaring a property would return the
modifier descriptor itself. Let's see the specific usages for each
properties with concrete examples.

#### times

By using mocks, we are saying that the injected method should be called
exactly once. However the injected method might be called more than once,
say, twice. We could specify this with `times` modifier:

``` ruby
obj = Object.new
mock(obj).name{ 'obj' }.times(2)
p obj.name     # 'obj'
p obj.name     # 'obj'
p Muack.verify # true
```

This is actually also semantically equivalent to making the mock twice:

``` ruby
obj = Object.new
mock(obj).name{ 'obj' }
mock(obj).name{ 'obj' }
p obj.name     # 'obj'
p obj.name     # 'obj'
p Muack.verify # true
```

Note that it does not make sense to specify `times` for stubs, because
stubs don't care about times. Spies do, though. So this is also
semantically equivalent to below:

``` ruby
obj = Object.new
stub(obj).name{ 'obj' }
p obj.name     # 'obj'
p obj.name     # 'obj'
spy(obj).name.times(2)
p Muack.verify # true
```

Or without using times for spy:

``` ruby
obj = Object.new
stub(obj).name{ 'obj' }
p obj.name     # 'obj'
p obj.name     # 'obj'
spy(obj).name
spy(obj).name
p Muack.verify # true
```

The advantage of specifying mocks twice is that we could actually provide
different results for each call. You could think of it as a stack. Here's
a simple example:

``` ruby
obj = Object.new
mock(obj).name{ 0 }
mock(obj).name{ 1 }
mock(obj).name{ 2 }
p obj.name     # 0
p obj.name     # 1
p obj.name     # 2
p Muack.verify # true
```

Note that this does not apply to stubs because stubs never run out, thus
making stubs defined later have no effects at all.

``` ruby
obj = Object.new
stub(obj).name{ 0 }
stub(obj).name{ 1 }
stub(obj).name{ 2 }
p obj.name     # 0
p obj.name     # 0
p obj.name     # 0
p Muack.verify # true
```

#### with_any_args

We haven't talked about verifying arguments. With `with_any_args` modifier,
we're saying that we don't care about the arguments. If we're not specifying
any arguments like above examples, we're saying there's no arguments at all.

Here we'll show an example for `with_any_args`. If you do want to verify some
specific arguments, jump to _Arguments Verifiers_ section.

``` ruby
obj = Object.new
mock(obj).name{ 'obj' }.with_any_args.times(4)
p obj.name       # 'obj'
p obj.name(1)    # 'obj'
p obj.name(nil)  # 'obj'
p obj.name(true) # 'obj'
p Muack.verify
```

#### returns

For some methods, we can't really pass a block to specify the implementation.
For example, we can't pass a block to `[]`, which is a Ruby syntax limitation.
To workaround it, we could use `returns` property:

``` ruby
obj = Object.new
mock(obj)[0].returns{ 0 }
p obj[0]       # 0
p Muack.verify # true
```

This is also useful when we want to put the implementation block in the last
instead of the beginning. Here's an example:

``` ruby
obj = Object.new
mock(obj).name.times(2).with_any_args.returns{ 'obj' }
p obj.name     # 'obj'
p obj.name     # 'obj'
p Muack.verify # true
```

On the other hand, there's also another advantage of using `returns` than
passing the block directly to the injected method. With `returns`, there's
an additional option we could use by passing arguments to `returns`. We
can't do this in regular injected method definition because those arguments
are for verifying the actual arguments. Jump to _Arguments Verifiers_ section
for details.

The only option right now is `:instance_exec`.

#### instance_exec mode

By default, the block passed to the injected method is lexically/statically
scoped. That means, the scope is bound to the current binding. This is the
default because usually we don't need dynamic scopes, and we simply want to
return a plain value, and this is much easier to understand, and it is the
default for most programming languages, and it would definitely reduce
surprises. If we really need to operate on the object, we have it, and
we could touch the internal by calling instance_eval on the object.

However, things are a bit different if we're using `any_instance_of`.
If we're using `any_instance_of`, then we don't have the instance at
hand at the time we're defining the block, but only a `Muack::AnyInstanceOf`
instance to represent the instance. There's no way we could really touch
the object without `instance_exec` option.

This would also be extremely helpful if we're using Muack as a monkey
patching library. We don't have to copy the original codes in order to
monkey patching a class, we could simply inject what we really want to
fix the internal stuffs in the broken libraries we're using. Jump to
_Muack as a mocky patching library_ section for more detail.

Here's an quick example:

``` ruby
any_instance_of(Array) do |array|
  p array.class # Muack::AnyInstanceOf
  mock(array).name.returns(:instance_exec => true){ inspect }
end
p [0, 1].name   # '[0, 1]'
p Muack.verify  # true
```

Note that this `:instance_exec` option also applies to other modifiers which
accepts a block for its implementation, i.e. `peek_args` and `peek_return`.

#### peek_args

What if we don't really want to change an underlying implementation for a
given method, but we just want to slightly change the arguments, or we
might just want to take a look at the arguments? Here's an example using
`peek_args` to modify the original arguments. Note that here we use the
proxy mode for the mock, because if we're defining our own behaviour,
then we already have full control of the arguments. There's no points to
use both. This also applies to `peek_return`.

``` ruby
str = 'ff'
mock(str).to_i.with_any_args.peek_args{ |radix| radix * 2 }
p str.to_i(8)  # 255
p Muack.verify # true
```

`peek_args` also supports `:instance_exec` mode.

#### peek_return

#### object

### Extra Topics

#### Muack as a mocky patching library

#### Muack as a development static typing system

### Recipes

### Coming from RR?

Basically since it's an RR clone, the APIs are much the same.
Let's see what's the different with code snippets. All codes
were extracted from
[RR's API document](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md).

#### [mock](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#mock)

`mock` is the same as RR.

``` ruby
view = controller.template
mock(view).render(:partial => "user_info") {"Information"}
```

There's no `twice` modifier in Muack, use `times(2)` instead.

``` ruby
mock(view).render.with_any_args.times(2).returns do |*args|
  if args.first == {:partial => "user_info"}
    "User Info"
  else
    "Stuff in the view #{args.inspect}"
  end
end
```

#### [stub](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#stub)

`stub` is the same as RR.

``` ruby
jane = User.new
bob = User.new
stub(User).find('42') {jane}
stub(User).find('99') {bob}
stub(User).find do |id|
  raise "Unexpected id #{id.inspect} passed to me"
end
```

#### [times(0)](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#dont_allow-aliased-to-do_not_allow-dont_call-and-do_not_call)

There's no dont_allow method in Muack, use `times(0)` instead.

``` ruby
User.find('42').times(0)
User.find('42') # raises a Muack::Unexpected
```

#### [proxy](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#mockproxy)

Instead of using another method for proxies, we simply do not pass any
block to the mocked method. You can think of the default block would be
the original method.

``` ruby
view = controller.template
mock(view).render(:partial => "right_navigation")
```

If you would like to peek the return value from the original method,
while returning a different result, you could use `peek_return`.
Note that `peek_return` works for non-proxies as well, just doesn't
make too much sense as you could already control the return value.

``` ruby
mock(view).render(:partial => "user_info").peek_return do |html|
  html.should include("John Doe")
  "Different html"
end
```

The same goes to `stub`.

``` ruby
view = controller.template
stub(view).render(:partial => "user_info").peek_return do |html|
  html.should include("Joe Smith")
  html
end
```

#### [any_instance_of](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#any_instance_of)

Only this form of `any_instance_of` is supported. On the other hand,
any of the above is supported as well, not only stub.

``` ruby
any_instance_of(User) do |u|
  stub(u).valid? { false }
  mock(u).errors { []    }
  mock(u).save
  stub(u).reload
end
```

#### [Spies](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#spies)

We don't try to provide different methods for different testing framework,
so that we don't have to create so many testing framework adapters, and
try to be smart to find the correct adapter. There are simply too many
testing frameworks out there. Ruby's built-in test/unit and minitest have
a lot of different versions, so does rspec.

Here we just try to do it the Muack's way:


``` ruby
subject = Object.new
stub(subject).foo(1){}
subject.foo(1)

spy(subject).foo(1)
spy(subject).bar # This doesn't verify immediately.
Muack.verify     # This fails, saying `bar` was never called.
```

#### [Block form](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#block-syntax)

Block form is also supported. However we don't support `instance_eval` form.
There's little point to use instance_eval since it's much more complicated
and much slower.

``` ruby
script = MyScript.new
mock(script) do |expect|
  expect.system("cd #{RAILS_ENV}") {true}
  expect.system("rake foo:bar") {true}
  expect.system("rake baz") {true}
end
```

#### [Nested mocks](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#double-graphs)

The shortest API (which might be a bit tricky) is not supported,
but we do support:

``` ruby
stub(object).foo { stub.bar{ :baz }.object }
object.foo.bar  #=> :baz
```

And of course the verbose way:

``` ruby
bar = stub.bar{ :baz }.object
stub(object).foo { bar }
object.foo.bar  #=> :baz
```

Or even more verbose, of course:

``` ruby
bar = Object.new
stub(bar).bar{ :baz }
stub(object).foo { bar }
object.foo.bar  #=> :baz
```

#### [Modifier](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#modifying-doubles)

After defining a mock method, you get a `Muack::Modifier` back.

``` ruby
stub(object).foo     #=> Muack::Modifier
```

However, you cannot flip around methods like RR. Whenever you define a
mock/stub method, you must provide the block immediately.

``` ruby
mock(object).foo{ 'bar' }.times(2)
```

If unfortunately, the method name you want to mock is already defined,
you can call `method_missing` directly to mock it. For example, `inspect`
is already defined in `Muack::Mock` to avoid crashing with [Bacon][].
In this case, you should do this to mock `inspect`:

``` ruby
mock(object).method_missing(:inspect){ 'bar' }.times(2)
```

#### [Stubbing method implementation / return value](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#stubbing-method-implementation--return-value)

Again, we embrace one true API to avoid confusion, unless the alternative
API really has a great advantage. So we encourage people to use the block to
return values. However, sometimes you cannot easily do that for certain
methods due to Ruby's syntax. For example, you can't pass a block to
a subscript operator `[]`. As a workaround, you can do it with
`method_missing`, though it's not very obvious if you don't know
what is `method_missing`.

``` ruby
stub(object).method_missing(:[], is_a(Fixnum)){ |a| a+1 }
object[1]  #=> 2
```

Instead you can do this with `returns`:

``` ruby
stub(object)[is_a(Fixnum)].returns{ |a| a + 1 }
object[1]  #=> 2
```

On the other hand, since Muack is more strict than RR. Passing no arguments
means you really don't want any argument. Here we need to specify the
argument for Muack. The example in RR should be changed to this in Muack:

``` ruby
stub(object).foo(is_a(Fixnum), anything){ |age, count, &block|
  raise 'hell' if age < 16
  ret = block.call count
  blue? ? ret : 'whatever'
}
```

Or if you would like to go with `with_any_args`:

``` ruby
stub(object).foo{ |age, count, &block|
  raise 'hell' if age < 16
  ret = block.call count
  blue? ? ret : 'whatever'
}.with_any_args
```

Or if you would like to put `with_any_args` in the front:

``` ruby
stub(object).foo.with_any_args.returns{ |age, count, &block|
  raise 'hell' if age < 16
  ret = block.call count
  blue? ? ret : 'whatever'
}
```

#### [Stubbing method implementation based on argument expectation](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#stubbing-method-implementation-based-on-argument-expectation)

Here is exactly the same as RR.

``` ruby
stub(object).foo { 'bar' }
stub(object).foo(1, 2) { 'baz' }
object.foo        #=> 'bar'
object.foo(1, 2)  #=> 'baz'
```

#### [Stubbing method to yield given block](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#stubbing-method-to-yield-given-block)

Always use the block to pass whatever back.

``` ruby
stub(object).foo{ |&block| block.call(1, 2, 3) }
object.foo {|*args| args } # [1, 2, 3]
```

#### [Expecting method to be called with exact argument list](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-with-exact-argument-list)

Muack is strict, you always have to specify the argument list.

``` ruby
mock(object).foo(1, 2)
object.foo(1, 2)   # ok
object.foo(3)      # fails
```

Passing no arguments really means passing no arguments.

``` ruby
stub(object).foo{}
stub(object).foo(1, 2){}
object.foo(1, 2)   # ok
object.foo         # ok
object.foo(3)      # fails
```

#### [Expecting method to be called with any arguments](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-with-any-arguments)

Muack also provides `with_any_args` if we don't really care.

``` ruby
stub(object).foo{}.with_any_args
object.foo        # ok
object.foo(1)     # also ok
object.foo(1, 2)  # also ok
                  # ... you get the idea
```

#### [Expecting method to be called with no arguments](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-with-no-arguments)

Just don't pass any argument :)

``` ruby
stub(object).foo{}
object.foo        # ok
object.foo(1)     # fails
```

#### [Expecting method to never be called](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-never-be-called)

Simply use `times(0)`.

``` ruby
mock(object).foo{}.times(0)
object.foo        # fails
```

Multiple mock with different argument set is fine, too.

``` ruby
mock(object).foo(1, 2){}.times(0)
mock(object).foo(3, 4){}
object.foo(3, 4)  # ok
object.foo(1, 2)  # fails
```

#### [Expecting method to be called only once](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-only-once)

By default, a mock only expects a call. Using `times(1)` is actually a no-op.

``` ruby
mock(object).foo{}.times(1)
object.foo
object.foo    # fails
```

#### [Expecting method to called exact number of times](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-called-exact-number-of-times)

Times! Which is the same as RR.

``` ruby
mock(object).foo{}.times(3)
object.foo
object.foo
object.foo
object.foo    # fails
```

Alternatively, you could also do this. It's exactly the same.

``` ruby
3.times{ mock(object).foo{} }
object.foo
object.foo
object.foo
object.foo    # fails
```

#### [Expecting method to be called minimum number of times](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-minimum-number-of-times)

It's not supported in Muack, but we could emulate it somehow:

``` ruby
times = 0
stub(object).foo{ times += 1 }
object.foo
object.foo
raise "BOOM" if times <= 3
```

#### [Expecting method to be called maximum number of times](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-maximum-number-of-times)


It's not supported in Muack, but we could emulate it somehow:

``` ruby
times = 0
stub(object).foo{ times += 1; raise "BOOM" if times > 3 }
object.foo
object.foo
object.foo
object.foo
```

#### [Expecting method to be called any number of times](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-any-number-of-times)

Just use `stub`, which is exactly why it is designed.

``` ruby
stub(object).foo{}
object.foo
object.foo
object.foo
```

#### [Argument wildcard matchers](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#argument-wildcard-matchers)

`anything` is the same as RR.

``` ruby
mock(object).foobar(1, anything){}
object.foobar(1, :my_symbol)
```

`is_a` is the same as RR.

``` ruby
mock(object).foobar(is_a(Time)){}
object.foobar(Time.now)
```

No numeric supports. Simply use `is_a(Numeric)`

``` ruby
mock(object).foobar(is_a(Numeric)){}
object.foobar(99)
```

No boolean supports, but you can use union (`|`).

``` ruby
mock(object).foobar(is_a(TrueClass) | is_a(FalseClass)){}
object.foobar(false)
```

Since duck_type is a weird name to me. Here we use `respond_to(:walk, :talk)`.

``` ruby
mock(object).foobar(respond_to(:walk, :talk)){}
arg = Object.new
def arg.walk; 'waddle'; end
def arg.talk; 'quack'; end
object.foobar(arg)
```

You can also use intersection (`&`) for multiple responses.
Though there's not much point here. Just want to demonstrate.

``` ruby
mock(object).foobar(respond_to(:walk) & respond_to(:talk)){}
arg = Object.new
def arg.walk; 'waddle'; end
def arg.talk; 'quack'; end
object.foobar(arg)
```

Don't pass ranges directly for ranges, use `within`. Or how do we tell
if we really want the argument to be a `Range` object?

``` ruby
mock(object).foobar(within(1..10)){}
object.foobar(5)
```

The same goes to regular expression. Use `match` instead.

``` ruby
mock(object).foobar(match(/on/)){}
object.foobar("ruby on rails")
```

`hash_including` is the same as RR.

``` ruby
mock(object).foobar(hash_including(:red => "#FF0000", :blue => "#0000FF")){}
object.foobar({:red => "#FF0000", :blue => "#0000FF", :green => "#00FF00"})
```

`satisfy` is the same as RR.

``` ruby
mock(object).foobar(satisfy {|arg| arg.length == 2 }){}
object.foobar("xy")
```

#### [Writing your own argument matchers](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#writing-your-own-argument-matchers)

See [`lib/muack.rb`][muack.rb] and [`lib/muack/satisfy.rb`][satisfy.rb],
you would get the idea soon. Here's how `is_a` implemented.

``` ruby
module Muack::API
  module_function
  def is_a klass
    Muack::IsA.new(klass)
  end
end

class Muack::IsA < Muack::Satisfy
  def initialize klass
    super lambda{ |actual_arg| actual_arg.kind_of?(klass) }, [klass]
  end
end
```

[muack.rb]: https://github.com/godfat/muack/blob/master/lib/muack.rb
[satisfy.rb]: https://github.com/godfat/muack/blob/master/lib/muack/satisfy.rb

## USERS:

* [Rib][]
* [rest-core](https://github.com/cardinalblue/rest-core)
* [rest-more](https://github.com/cardinalblue/rest-more)

## CONTRIBUTORS:

* Lin Jen-Shin (@godfat)

## LICENSE:

Apache License 2.0

Copyright (c) 2013, Lin Jen-Shin (godfat)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
