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

Valid for both RR and Muack

``` ruby
view = controller.template
mock(view).render(:partial => "user_info") {"Information"}
```

There's no `twice` modifier in Muack, use `times(2)` instead.

``` ruby
mock(view).render.with_any_args.times(2) do |*args|
  if args.first == {:partial => "user_info"}
    "User Info"
  else
    "Stuff in the view #{args.inspect}"
  end
end
```

#### [stub](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#stub)

Valid for both RR and Muack

``` ruby
jane = User.new
bob = User.new
stub(User).find('42') {jane}
stub(User).find('99') {bob}
stub(User).find do |id|
  raise "Unexpected id #{id.inspect} passed to me"
end
```

#### [dont_allow](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#dont_allow-aliased-to-do_not_allow-dont_call-and-do_not_call)

There's no `dont_allow` method in Muack, use `times(0)` instead.

``` ruby
User.find('42').times(0)
User.find('42') # raises a Muack::Unexpected
```

#### [mock.proxy](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#mockproxy)

Since I don't see how we gain from calling it `mock.proxy`, in Muack we
just call it `mock_proxy`.

``` ruby
view = controller.template
mock_proxy(view).render(:partial => "right_navigation")
mock_proxy(view).render(:partial => "user_info") do |html|
  html.should include("John Doe")
  "Different html"
end
```

#### [stub.proxy](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#stubproxy)

The same goes to `stub_proxy`.

``` ruby
view = controller.template
stub_proxy(view).render(:partial => "user_info") do |html|
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
  mock_proxy.save
  stub_proxy.reload
end
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

#### [Double graphs](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#double-graphs)

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

#### [Modifying doubles](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#modifying-doubles)

Instead of DoubleDefinition from RR, you get `Muack::Modifier`

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

Again, there's only one true API form you can use. On the other hand,
since Muack is more strict than RR. Passing no arguments means you
really don't want any argument. Here we need to specify the argument
for Muack. The example should be changed to:

``` ruby
stub(object).foo(is_a(Fixnum), anything){ |age, count, &block|
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
stub(object).foo
stub(object).foo(1, 2)
object.foo(1, 2)   # ok
object.foo         # ok
object.foo(3)      # fails
```

#### [Expecting method to be called with any arguments](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-with-any-arguments)

Muack also provides `with_any_args` if we don't really care.

``` ruby
stub(object).foo.with_any_args
object.foo        # ok
object.foo(1)     # also ok
object.foo(1, 2)  # also ok
                  # ... you get the idea
```

#### [Expecting method to be called with no arguments](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-with-no-arguments)

Just don't pass any argument :)

``` ruby
stub(object).foo
object.foo        # ok
object.foo(1)     # fails
```

#### [Expecting method to never be called](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-never-be-called)

Simply use `times(0)`.

``` ruby
mock(object).foo.times(0)
object.foo        # fails
```

Multiple mock with different argument set is fine, too.

```
mock(object).foo(1, 2).times(0)
mock(object).foo(3, 4)
object.foo(3, 4)  # ok
object.foo(1, 2)  # fails
```

#### [Expecting method to be called only once](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-be-called-only-once)

By default, a mock only expects a call. Using `times(1)` is actually a no-op.

``` ruby
mock(object).foo.times(1)
object.foo
object.foo    # fails
```

#### [Expecting method to called exact number of times](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#expecting-method-to-called-exact-number-of-times)

Times! Which is the same as RR.

``` ruby
mock(object).foo.times(3)
object.foo
object.foo
object.foo
object.foo    # fails
```

Alternatively, you could also do this. It's exactly the same.

``` ruby
3.times{ mock(object).foo }
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
stub(object).foo
object.foo
object.foo
object.foo
```

#### [Argument wildcard matchers](https://github.com/rr/rr/blob/e4b4907fd0488738affb4dab8ce88cbe9fa6580e/doc/03_api_overview.md#argument-wildcard-matchers)

The same as RR `anything`.

``` ruby
mock(object).foobar(1, anything)
object.foobar(1, :my_symbol)
```

The same as RR `is_a`.

``` ruby
mock(object).foobar(is_a(Time))
object.foobar(Time.now)
```

No numeric supports. Simply use `is_a(Numeric)`

``` ruby
mock(object).foobar(is_a(Numeric))
object.foobar(99)
```

No boolean supports. Pass a custom satisfy block for it:

``` ruby
mock(object).foobar(
  satisfy{ |a| a.kind_of?(TrueClass) || a.kind_of?(FalseClass) })
object.foobar(false)
```

No duck_type supports. Pass a custom satisfy block for it:

``` ruby
mock(object).foobar(
  satisfy{ |a| a.respond_to?(:walk) && a.respond_to?(:talk) })
arg = Object.new
def arg.walk; 'waddle'; end
def arg.talk; 'quack'; end
object.foobar(arg)
```

Don't pass ranges directly for ranges, use `within`. Or how do we tell
if we really want the argument to be a `Range` object?

``` ruby
mock(object).foobar(within(1..10))
object.foobar(5)
```

The same goes to regular expression. Use `match` instead.

``` ruby
mock(object).foobar(match(/on/))
object.foobar("ruby on rails")
```

The same as RR `hash_including`.

``` ruby
mock(object).foobar(hash_including(:red => "#FF0000", :blue => "#0000FF"))
object.foobar({:red => "#FF0000", :blue => "#0000FF", :green => "#00FF00"})
```

The same as RR `satisfy`.

``` ruby
mock(object).foobar(satisfy {|arg| arg.length == 2 })
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
