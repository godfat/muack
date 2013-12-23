# Muack [![Build Status](https://secure.travis-ci.org/godfat/muack.png?branch=master)](http://travis-ci.org/godfat/muack)

by Lin Jen-Shin ([godfat](http://godfat.org))

## LINKS:

* [github](https://github.com/godfat/muack)
* [rubygems](https://rubygems.org/gems/muack)
* [rdoc](http://rdoc.info/github/godfat/muack)

## DESCRIPTION:

Muack -- Yet another mocking library.

Basically it's an [RR][] clone, but much faster under heavy use.
It's 32x times faster (750s vs 23s) for running [Rib][] tests.

[RR]: https://github.com/rr/rr
[Rib]: https://github.com/godfat/rib

## WHY?

Because RR has/had some bugs and it is too complex for me to fix it.
Muack is much simpler and thus much faster and less likely to have bugs.

## REQUIREMENTS:

* Tested with MRI (official CRuby) 1.9.3, 2.0.0, Rubinius and JRuby.

## INSTALLATION:

    gem install muack

## SYNOPSIS:

Basically it's an [RR][] clone. Let's see a [Bacon][] example.

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

You can also pass a value directly to `returns` if you only want to return
a simple value.

``` ruby
stub(object)[is_a(Fixnum)].returns(2)
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
