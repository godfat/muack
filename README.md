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

Note that you could also mix mocks and stubs for a given object.
Here's an example:

``` ruby
obj = Object.new
stub(obj).name{ 'obj' }
mock(obj).id  { 12345 }
p obj.name     # 'obj'
p obj.id       # 12345
p Muack.verify # true
```

However you should not mix mocks and stubs with the same method, or you
might encounter some unexpected result. Jump to _Caveat_ for more detail.

#### Anonymous mode

Sometimes we just want to stub something without a concrete object in mind.
By calling `mock` or `stub` without any argument, we're creating an anonymous
mock/stub. This is because the default argument for `mock` and `stub` is just
`Object.new`.

But how do we access the anonymously created object? We'll use the `object`
method on the modifier to access it. Here's an example:

``` ruby
obj = mock.name{ 'obj' }.object
p obj.name     # 'obj'
p Muack.verify # true
```

This is exactly equivalent to this:

``` ruby
mock(obj = Object.new).name{ 'obj' }
p obj.name     # 'obj'
p Muack.verify # true
```

Also, if we want to mock over multiple methods, we could also take the
advantage of block form of `mock` and `stub` method.

``` ruby
obj = mock{ |m|
  m.name{ 'obj' }
  m.id  { 12345 }
}.object
p obj.name     # 'obj'
p obj.id       # 12345
p Muack.verify # true
```

We can't omit the `object` method here because after defining the injected
method, we'll get a modifier to describe the properties of the injected
method. Jump to _Mocks Modifiers_ for details.

#### Proxy mode

There are chances that we don't really want to change the underlying
implementation for a given method, but we still want to make sure the
named method is called, and that's what we're testing for.

In those cases, proxy mode would be quite helpful. To turn a mock or stub
into proxy mode we simply do not provide any block to the injected method,
but just name it. Here's an example:

``` ruby
str = 'str'
mock(str).reverse
p str.reverse  # 'rts'
p Muack.verify # true
```

Note that if reverse was not called exactly once, the mock would complain.
We could also use stub + spy to do the same thing as well:

``` ruby
str = 'str'
stub(str).reverse
p str.reverse  # 'rts'
spy(str).reverse
p Muack.verify # true
```

You might also want to use `peek_args` and `peek_return` modifier along with
proxies in order to slightly tweak the original implementation. Jump to
_Muack as a mocky patching library_ section for more detail.

#### any_instance_of mode

We only talked about mocking a specific object, but never mentioned what if
the objects we want to mock aren't at hand at the time we define mocks?
In those cases, instead of trying to mock object creation and return the
mock we defined, we might want to simply mock any instance of a particular
class, since this would make the process much easier.

Here we could use a special "mock" called `any_instance_of`, which takes a
class and returns a `Muack::AnyInstanceOf` which represents the instance of
the class we just passed. Having this special representation, we could treat
it as if a real instance and define regular mocks/stubs on it. It would then
applies to any instance of the class we gave.

Example speaks:

``` ruby
array = any_instance_of(Array)
stub(array).name{ 'array' }
p [ ].name     # 'array'
p [0].name     # 'array'
p Muack.verify # true
```

And as most of the time we don't care about the representation after mocks
were defined, we could use the block form:

``` ruby
any_instance_of(Array) do |array|
  stub(array).name{ 'array' }
  stub(array).id  { 1234567 }
end
p [ ].name   # 'array'
p [0].id     # 1234567
p Muack.verify # true
```

Note that if you need to access the real instance instead of the
representation in the injected method, you might want to enable
instance_exec mode. Please jump to _instance_exec mode_ section
for more detail.

Here's an quick example:

``` ruby
any_instance_of(Array) do |array|
  p array.class # Muack::AnyInstanceOf
  mock(array).name.returns(:instance_exec => true){ inspect }
end
p [0, 1].name   # '[0, 1]'
p Muack.verify  # true
```

Lastly, you could also use `any_instance_of` along with proxy mode,
or any other combination you could think of:

``` ruby
any_instance_of(Array) do |array|
  stub(array).name{ 'array' }
  mock(array).max
end
p [ ].name     # 'array'
p [0].max      # 0
p Muack.verify # true
```

Though you should still not mix mocks and stubs with the same method,
and as you could tell from the above example, Muack would not complain
for every array without calling `max` once. This is because any_instance_of
would count on all instances, instead of individual instances. Here
we're actually telling Muack that `max` should be called exactly once
amongst all instances of array, and it is indeed called exactly once
amongst two instances here.

This might or might not be what we want. But think it twice, if we're
mocking any instance of a very basic class in Ruby, testing against
individual instances could be too strict since it's used everywhere!

Please check _Caveat_ section for more details.

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

We could also use the block form for convenience:

``` ruby
obj = Object.new
mock(obj) do |m|
  m.name{ 0 }
  m.name{ 1 }
  m.name{ 2 }
end
p obj.name     # 0
p obj.name     # 1
p obj.name     # 2
p Muack.verify # true
```

Note that this does not apply to stubs because stubs never run out, thus
making stubs defined later have no effects at all.

``` ruby
obj = Object.new
stub(obj) do |m|
  m.name{ 0 }
  m.name{ 1 }
  m.name{ 2 }
end
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
p Muack.verify   # true
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
`peek_args` to modify the original arguments.

Note that here we use the proxy mode for the mock, because if we're defining
our own behaviour, then we already have full control of the arguments.
There's no points to use both. This also applies to `peek_return`.

``` ruby
str = 'ff'
mock(str).to_i.with_any_args.peek_args{ |radix| radix * 2 }
p str.to_i(8)  # 255
p Muack.verify # true
```

`peek_args` also supports `:instance_exec` mode. Here's an example:

``` ruby
any_instance_of(Array) do |array|
  stub(array).push.with_any_args.
    peek_args(:instance_exec => true){ |_| size }
end
a = []
p a.push       # [0]
p a.push       # [0, 1]
p a.push       # [0, 1, 2]
p Muack.verify # true
```

We could also omit `|_|` if we don't care about the original argument
in the above example.

#### peek_return

What if we don't really want to change an underlying implementation for a
given method, but we just want to slightly change the return value, or we
might just want to take a look at the return? Here's an example using
`peek_return` to modify the original return value.

``` ruby
str = 'ff'
mock(str).to_i.with_any_args.peek_return{ |int| int * 2 }
p str.to_i(16) # 510
p Muack.verify # true
```

`peek_return` also supports `:instance_exec` mode. Here's an example:

``` ruby
any_instance_of(Array) do |array|
  stub(array).push.with_any_args.
    peek_return(:instance_exec => true){ |_| size }
end
a = []
p a.push(0)    # 1
p a.push(0)    # 2
p a.push(0)    # 3
p a            # [0, 0, 0]
p Muack.verify # true
```

We could also omit `|_|` if we don't care about the original return value
in the above example.

### Arguments Verifiers (Satisfy)

If we're not passing any arguments to the injected method we define, then
basically we're saying that there's no arguments should be passed to the
method. If we don't care about the arguments, then we should use
`with_any_args` modifier. If we want the *exact* arguments, then we
should just pass the arguments, which would be checked with `==` operator.

Here's an example:

``` ruby
obj = Object.new
mock(obj).say('Hi'){ |arg| arg }
p obj.say('Hi') # 'Hi'
p Muack.verify  # true
```

This also applies to multiple arguments:

``` ruby
obj = Object.new
mock(obj).say('Hello', 'World'){ |*args| args.join(', ') }
p obj.say('Hello', 'World') # 'Hello, World'
p Muack.verify  # true
```

What if we don't want to be so exact? Then we should use verifiers.
We'll introduce each of them in next section. Note that verifiers
are not recursive though. If you need complex argument verification,
you'll need to use `satisfy` verifier which you could give an arbitrary
block to verify anything.

#### is_a

`is_a` would check if the argument is a kind of the given class.
Actually, it's calling `kind_of?` underneath.

``` ruby
obj = Object.new
mock(obj).say(is_a(String)){ |arg| arg }
p obj.say('something') # 'something'
p Muack.verify         # true
```

#### anything

`anything` is a wildcard argument verifier. It matches anything.
Although this actually verifies nothing, we could still think of
this as an arity verifier. Since one anything is not two anythings.

``` ruby
obj = Object.new
mock(obj).say(anything){ |arg| arg }.times(2)
p obj.say(0)    # 0
p obj.say(true) # true
p Muack.verify  # true
```

#### match

`match` would check the argument with `match` method. Usually this is
used with regular expression, but anything which responds to `match`
should work.

``` ruby
obj = Object.new
mock(obj).say(match(/\w+/)){ |arg| arg }
p obj.say('Hi') # 'Hi'
p Muack.verify  # true
```

Note that please don't pass the regular expression directly without
wrapping it with a match verifier, or how do we distinguish if we
really want to make sure the argument is exactly the regular expression?

#### hash_including

`hash_including` would check if the given hash is the actual
argument's subset.

``` ruby
obj = Object.new
mock(obj).say(hash_including(:a => 0)){ |arg| arg }
p obj.say(:a => 0, :b => 1) # {:a => 0, :b => 1}
p Muack.verify # true
```

#### including

`including` would check if the actual argument includes the given value
via `include?` method.

``` ruby
obj = Object.new
mock(obj).say(including(0)){ |arg| arg }
p obj.say([0,1]) # [0,1]
p Muack.verify   # true
```

#### within

`within` is the reverse version of `including`, verifying if the actual
argument is included in the given value.

``` ruby
obj = Object.new
mock(obj).say(within([0, 1])){ |arg| arg }
p obj.say(0)   # 0
p Muack.verify # true
```

#### respond_to

`respond_to` would check if the actual argument would be responding to
the given message, checked via `respond_to?`, also known as duck typing.

``` ruby
obj = Object.new
mock(obj).say(respond_to(:size)){ |arg| arg }
p obj.say([])  # []
p Muack.verify # true
```

Note that you could give multiple messages to `respond_to`.

``` ruby
obj = Object.new
mock(obj).say(respond_to(:size, :reverse)){ |arg| arg }
p obj.say([])  # []
p Muack.verify # true
```

#### satisfy

`satisfy` accepts a block to let you do arbitrary verification.
nil and false are considered false, otherwise true, just like in
regular if expression.

``` ruby
obj = Object.new
mock(obj).say(satisfy{ |arg| arg % 2 == 0 }){ |arg| arg }
p obj.say(0)   # 0
p Muack.verify # true
```

#### Disjunction (|)

If what we want is the actual argument be within either `0..1` or `3..4`?
We don't really have to use `satisfy` to build custom verifier, we could
compose verifiers with disjunction operator (|).

``` ruby
obj = Object.new
mock(obj).say(within(0..1) | within(3..4)){ |arg| arg }.times(2)
p obj.say(0)   # 0
p obj.say(4)   # 4
p Muack.verify # true
```

Or boolean, you might say:

``` ruby
obj = Object.new
mock(obj).say(is_a(TrueClass) | is_a(FalseClass)){ |arg| arg }.times(2)
p obj.say(true)  # true
p obj.say(false) # false
p Muack.verify   # true
```

#### Conjunction (&)

If what we want is the actual argument not only a kind of something,
but also responds to something. For example, an Enumerable requires the
class implements each method. We could use conjunction for this.

``` ruby
obj = Object.new
mock(obj).say(is_a(Enumerable) & respond_to(:each)){}.times(3)
p obj.say( [] ) # nil
p obj.say( {} ) # nil
p obj.say(0..1) # nil
p Muack.verify  # true
```

### Caveat

#### Mixing mocks and stubs

We could and probably would also want to mix mocks and stubs, for example,
we might be concerned about some methods for a given object, but not the
other methods.

``` ruby
obj = Object.new
stub(obj).name{ 'obj' }
mock(obj).id  { 12345 }
obj.name     # 'obj'
obj.name     # 'obj'
obj.id       # 12345
Muack.verify # true
```

However, it might act unexpectedly if we mock and stub on the same object
for the same method. It would somehow act like the latter would always win!
So if we define mock later for the same method, previously defined stub
would never be called. On the other hand, if we define stub later for the
same method, previously defined mock would always complain because it would
never be called, either!

This does not mean previously defined mocks or stubs get overwritten, because
it would still take effect. It's just that there's no way they could get
called. So this is mostly not desired.

The ideal solution to this would be raising an error immediately, or really
make it could be overwritten. However I didn't find a good way to handle this
without rewriting the internal details. So I'll just leave it as it is,
and hope no one would ever try to do this.

#### any_instance_of shares all calls for a given class

We might assume that mocks with any_instance_of would work exactly the same
as regular mocks, but this is actually not the case. Regular mocks count
on every individual instance, but all instances share the same count for
any_instance_of.

With one instance:

``` ruby
any_instance_of(Array){ |array| mock(array).f{true}.times(2) }
a = []
a.f          # true
a.f          # true
Muack.verify # true
```

With two instances:

``` ruby
any_instance_of(Array){ |array| mock(array).f{true}.times(2) }
[].f         # true
[].f         # true
Muack.verify # true
```

So remember to count on all instances, but not individual ones.

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
