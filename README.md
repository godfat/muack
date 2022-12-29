# Muack [![Pipeline status](https://gitlab.com/godfat/muack/badges/master/pipeline.svg)](https://gitlab.com/godfat/muack/-/pipelines)

by Lin Jen-Shin ([godfat](http://godfat.org))

## LINKS:

* [github](https://github.com/godfat/muack)
* [rubygems](https://rubygems.org/gems/muack)
* [rdoc](http://rdoc.info/github/godfat/muack)
* [issues](https://github.com/godfat/muack/issues) (feel free to ask for support)

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

* Tested with MRI (official CRuby) and JRuby.

## INSTALLATION:

    gem install muack

## SYNOPSIS:

Here's a quick example using [Pork][].

``` ruby
require 'pork/auto'
require 'muack'

describe 'Hello' do
  include Muack::API

  before{ Muack.reset  }
  after { Muack.verify }

  would 'say world!' do
    str = 'Hello'.dup
    mock(str).say('!'){ |arg| "World#{arg}" }
    str.say('!').should.eq 'World!'
  end
end
```

[Pork]: https://github.com/godfat/pork

### Overview

There are 3 parts in Muack, which are:

* [Mocks](#mocks)
* [Mocks Modifiers](#mocks-modifiers)
* [Arguments Verifiers (Satisfying)](#arguments-verifiers-satisfying)

Mocks are objects with injected methods which we could observe, and mocks
modifiers are telling how we want to observe the mocks, and finally argument
verifiers could help us observe the arguments passed to the injected methods.

Let's explain them one by one.

### Mocks

There are also 4 different kinds of mocks in Muack, which are:

* Mocks
* Stubs
* Spies
* Coats

You could think of _mocks_ are sort of _stubs_ combined with _spies_.
Here's the inequation: (we'll talk about _coats_ later)

    mock >= stub + spy

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

Which is similar to using a stub with a spy:

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

The other difference is that, spies could partially verify the corresponding
stubs, but not necessarily completely as mocks. For example, we could stub
two methods, but only verify one of them with a spy.

``` ruby
obj = Object.new
stub(obj).name{ 'obj' }
stub(obj).id  { 12345 }
p obj.name     # 'obj'
p obj.id       # 12345
spy(obj).name
p Muack.verify # true
```

This is similar as mixing mocks and stubs, as in the following example:

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

The other differences for stubs and spies, please check
[Pattern Matching for stubs and spies][pattern-matching].
In short, stubs and spies would do some kind of pattern matching,
making the order of the same method irrelevant.

On the other hand, stubs aren't limited to testing. If we want to monkey
patching something, stubs could be useful as we don't care how many times
the injected methods are called. Jump to _Muack as a mocky patching library_
section for more detail.

### reset and verify

Calling `Muack.reset` is essentially resetting all mocks, returning all
objects/classes back to their original states. In the very first example,
we do this in a before block to make sure that we're in a clean state.

Calling `Muack.verify` is essentially verifying if all mocks and spies are
satisfied, if so, it would return true; otherwise, raising an exception.
Then, no matter verification passed or not, Muack would reset itself.

That means we don't really need to call `Muack.reset` in a before block if
we're pretty sure that all test cases would call `Muack.verify` in the end,
resetting everything.

On the other hand, we could also reset or verify a single object without
affecting the others. This is helpful in the cases of mocking some very
basic objects like Time, without causing too much side effect.

``` ruby
name = 'str'.dup
stub(name).to_s{ 'hi'       }
stub(Time).new { Time.at(0) }
mock(Time).now { Time.new   }

p name.to_s          # 'hi'
p Time.now.to_i      # 0
p Time.new.to_i      # 0
p Muack.verify(Time) # true
p name.to_s          # 'hi'
p Time.now.to_i > 0  # true
p Time.new.to_i > 0  # true
Muack.reset(name)
p name.to_s          # 'str'
p Muack.verify       # true
```

### Coats

Now we could talk about coats. It's a kind of mocks but it would wear out
instead of raising an exception when it's called more than expected times.
This is useful when we want to restore the original behaviour of a
particular method at some point. The problem is that we can't simply
call the original method because it's already mocked! We could workaround
this by using `Muack.verify` or `Muack.reset` at some point, or let _coats_
handle that.

Here's an example with _coats_:

``` ruby
coat(Time).now{ Time.at(0) }.times(2)

p Time.now.to_i == 0 # true
p Time.now.to_i == 0 # true
p Time.now.to_i  > 0 # true
p Muack.verify       # true
```

Without _coats_ we might end up with:

``` ruby
mock(Time).now{ Time.at(0) }
mock(Time).now{ Muack.verify(Time); Time.at(0) }

p Time.now.to_i == 0 # true
p Time.now.to_i == 0 # true
p Time.now.to_i  > 0 # true
p Muack.verify       # true
```

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
str = 'str'.dup
mock(str).reverse
p str.reverse  # 'rts'
p Muack.verify # true
```

Note that if reverse was not called exactly once, the mock would complain.
We could also use stub + spy to do the same thing as well:

``` ruby
str = 'str'.dup
stub(str).reverse
p str.reverse  # 'rts'
spy(str).reverse
p Muack.verify # true
```

You might also want to use `peek_args` and `peek_return` modifier along with
proxies in order to slightly tweak the original implementation. Jump to
_Muack as a mocky patching library_ section for more detail.

#### Partial mode

Occasionally we would want to fake some of the values inside a hash, but
we don't want to interfere with the other values in that hash, and we also
don't want to modify it directly, or we'll need to make sure to restore it
after the tests.

Partial mode is not really a mode, but a combination of using proxy mode and
the [pattern matching mechanism specialized in stubs][pattern-matching].
Suppose we want to stub `ENV` (which is not a hash but you get the idea),
enabling some of the flags inside tests without really setting it, we'll do:

``` ruby
@user = ENV['USER']
p ENV['NDEBUG'] # nil

stub(ENV)[is_a(String)] #- NOTE: NEED TO DEFINE THIS PROXY FIRST
stub(ENV)['NDEBUG'].returns{ '1' } #- `returns` workaround Ruby syntax

p ENV['NDEBUG'] # '1'
p ENV['USER']   # @user
p Muack.verify  # true
p ENV['NDEBUG'] # nil
```

Note that in order to make this work, proxy should be defined first. Because
stubs are searched in Last In First Out (LIFO) order, it would first check
if the key is matching `'NDEBUG'` in this case. If it's not matched, then
search the next one. Eventually it would reach to the first stub, which
we put `is_a(String)` there so it must match, and return the original value
inside `ENV`.

If the order is reversed, then it would always return the original value,
because the proxy would always match, and Muack would stop searching the
next stub.

[pattern-matching]: #pattern-matching-for-stubs-and-spies

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
similar to below:

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

Note that this does not apply to stubs because stubs never run out. Instead,
the latter stub would overwrite the previous one.

``` ruby
obj = Object.new
stub(obj) do |m|
  m.name{ 0 }
  m.name{ 1 }
  m.name{ 2 }
end
p obj.name     # 2
p obj.name     # 2
p obj.name     # 2
p Muack.verify # true
```

Note that if you do not want a given method be called at all, you could
use `times(0)` to enforce this.

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
str = 'ff'.dup
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
p a.push.dup   # [0]
p a.push.dup   # [0, 1]
p a.push.dup   # [0, 1, 2]
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
str = 'ff'.dup
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

### Arguments Verifiers (Satisfying)

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

We could also retrieve the block argument:

``` ruby
obj = Object.new
mock(obj).say{ |&block| block.call('Hi') }
obj.say{ |msg| p msg } # 'Hi'
p Muack.verify  # true
```

#### Pattern Matching for stubs and spies

Moreover, we could also have stubs on the same method for different
arguments. We could think of this as a sort of pattern matching, and Muack
would try to find the best matched stub for us.

``` ruby
obj = Object.new
stub(obj).find(0){ 0 }
stub(obj).find(1){ 1 }
p obj.find(1)  # 1
p obj.find(0)  # 0
p Muack.verify # true
```

If `obj.find(2)` is called and Muack cannot find a matched stub, it would
raise a `Muack::Unexpected` and list the candidates for us. This also
applies to spies.

However, What if we don't want to be so exact? Then we should use verifiers.
We'll introduce each of them in next section. Note that verifiers
are not recursive though. If you need complex arguments verification,
you'll need to use `satisfy` verifier which you could give an arbitrary
block to verify anything.

#### anything

`anything` is a wildcard arguments verifier. It matches anything.
Although this actually verifies nothing, we could still think of
this as an arity verifier. Since one anything is not two anythings.

``` ruby
obj = Object.new
mock(obj).say(anything){ |arg| arg }.times(2)
p obj.say(0)    # 0
p obj.say(true) # true
p Muack.verify  # true
```

#### is_a

`is_a` would check if the argument is a kind of the given class.
Actually, it's calling `kind_of?` underneath.

``` ruby
obj = Object.new
mock(obj).say(is_a(String)){ |arg| arg }
p obj.say('something') # 'something'
p Muack.verify         # true
```

#### matching

`matching` would check the argument with `match` method. Usually this is
used with regular expression, but anything which responds to `match`
should work.

``` ruby
obj = Object.new
mock(obj).say(matching(/\w+/)){ |arg| arg }
p obj.say('Hi') # 'Hi'
p Muack.verify  # true
```

Note that please don't pass the regular expression directly without
wrapping it with a match verifier, or how do we distinguish if we
really want to make sure the argument is exactly the regular expression?

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

#### responding_to

`responding_to` would check if the actual argument would be responding to
the given message, checked via `respond_to?`, also known as duck typing.

``` ruby
obj = Object.new
mock(obj).say(responding_to(:size)){ |arg| arg }
p obj.say([])  # []
p Muack.verify # true
```

Note that you could give multiple messages to `responding_to`.

``` ruby
obj = Object.new
mock(obj).say(responding_to(:size, :reverse)){ |arg| arg }
p obj.say([])  # []
p Muack.verify # true
```

#### where

`where` would check if the actual argument matches given specification.

``` ruby
obj = Object.new
mock(obj).say(where(:a => is_a(Integer))){ |arg| arg }
p obj.say(:a => 0) # {:a => 0}
p Muack.verify # true
```

Note that this could be recursive.

``` ruby
obj = Object.new
mock(obj).say(where(:a => {:b => [is_a(Integer)]})){ |arg| arg[:a] }
p obj.say(:a => {:b => [0]}) # {:b => [0]}
p Muack.verify # true
```

#### having

`having` would check if the actual argument is a superset of given
specification.

``` ruby
obj = Object.new
mock(obj).say(having(:a => 0)){ |arg| arg }
p obj.say(:a => 0, :b => 1) # {:a => 0, :b => 1}
p Muack.verify # true
```

Note that this could be recursive.

``` ruby
obj = Object.new
mock(obj).say(having(:a => {:b => [is_a(Integer)]})){ |arg| arg[:c] }
p obj.say(:a => {:b => [1]}, :c => 2) # 2
p Muack.verify # true
```

#### allowing

`allowing` would check if the actual argument is a subset of given
specification.

``` ruby
obj = Object.new
mock(obj).say(allowing(:a => 0, :b => [1])){ |arg| arg }
p obj.say(:a => 0) # {:a => 0}
p Muack.verify # true
```

Note that this could be recursive.

``` ruby
obj = Object.new
mock(obj).say(allowing(:a => {:b => is_a(Integer), :c => 1})){ |arg| arg[:a] }
p obj.say(:a => {:b => 2}) # {:b => 2}
p Muack.verify # true
```

#### satisfying

`satisfying` accepts a block to let you do arbitrary verification.
nil and false are considered false, otherwise true, just like in
regular if expression.

``` ruby
obj = Object.new
mock(obj).say(satisfying{ |arg| arg % 2 == 0 }){ |arg| arg }
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
mock(obj).say(is_a(Enumerable) & responding_to(:each)){}.times(3)
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
p obj.name     # 'obj'
p obj.name     # 'obj'
p obj.id       # 12345
p Muack.verify # true
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
p a.f          # true
p a.f          # true
p Muack.verify # true
```

With two instances:

``` ruby
any_instance_of(Array){ |array| mock(array).f{true}.times(2) }
p [].f         # true
p [].f         # true
p Muack.verify # true
```

So remember to count on all instances, but not individual ones.

### Extra Topics

#### Muack as a mocky patching library

Consider you're using a broken library and you need an immediate fix without
waiting for upstream to merge your patch, and release a new version.

You could fix it more elegantly by subclassing the original class, or try to
include or extend a module to make the original class work correctly. But
sometimes we just cannot do this because of the implementation. They might
not be extensible at all. Consider if there's a method contains 1,000
lines... There's no way to change it in the middle of the method other than
touching the lines directly, unless we have some line based AOP tools...
which is not really practical.

In this case, we could fork it and maintain everything by ourselves, and
merge from upstream occasionally. However we might only want to do this as
the last resort since this could cost a lot.

Alternatively, we can copy the original code, and put it somewhere, and
load it after the original code was loaded, so we have the patched and
correct code running. This is also called monkey patching, patching like a
monkey. Generally this is a bad idea, but sometimes we can only do this to
workaround some broken libraries. For example, some libraries might not be
maintained, or the authors refused to fix this due to other reasonable or
unreasonable reason.

The most notable drawback of monkey patching is that, we're copying a lot of
codes which could be changed upstream, and we might not be aware of that,
and update our monkey patch accordingly. This could cause some incompatible
issues.

That means, the fewer copied codes, the better. Muack could actually help
in this case. I called this mocky patching. The advantage of using this
technique is that, we have `peek_args` and `peek_return` which we could
modify the arguments or return values in runtime, without changing any
implementation of a particular method.

Here's a real world example with rails_admin. The problem in rails_admin is
that, it assumes every associated records should have already been saved,
thus having an id, and there's also a particular show page for it.

However, in our application, we could have associated records not yet saved
in the database. rails_admin would try to retrieve routes for those unsaved
records, and rails would raise RoutingError because rails_admin is passing
no id for a show path.

The idea of this fix is simple. Just don't try to get the show page for
records which are not yet saved, i.e. records without an id. However this
is actually extremely hard to fix in rails_admin without monkey patching!

I'll skip all those details and my rants. In the end, I fixed this by
trying to peek the arguments for a particular method, and if and only if
the passed records are not yet saved in the database, we fake the arguments.
Otherwise, we just bypass and fallback to the original implementation.

Here's the code:

```  ruby
Muack::API.stub(RailsAdmin::Config::Actions).find.with_any_args.
  peek_args do |*args|
    custom_key, bindings = args
    if bindings && bindings[:object] && bindings[:object].id.nil?
      [nil, {}] # There's no show page for unsaved records
    else
      args # Bypass arguments
    end
  end
```

If we don't do mocky patching but monkey patching, we'll end up with
copying the entire method for RailsAdmin::Config::Actions.find, which then,
we'll be responsible for updating this method if some of the original
implementation changed.

Note that in mocky patching, we should always use stub and never call
`Muack.verify` or `Muack.reset`, or that would defeat the purpose of
mocky patching.

#### Muack as a development runtime static typing system

Ever consider a static type system in Ruby? You could actually see a lot of
asserts inserted in the beginning of some methods in some libraries. For
example, there are `assert_valid_key_size`, `assert_kind_of`, etc, in
[dm-core][], and `assert_valid_keys`, `assert_valid_transaction_action`,
and various random asserts in activerecord.

You could find them by searching against `raise ArgumentError` because
rails is much less consistent and sometimes it's hard to find a pattern in
rails. But you get the idea, those `ArgumentError` would much help us debug
our code from misusing the API, and that's exactly the point of type system,
or more specifically, static type system.

We could also use some static analysis tools to do something like this, for
example, there's [ruby-lint][]. However, as you might already know, since
Ruby is so dynamic, static analysis tools cannot really do a great job if
our code is quite dynamic. Of course we could write it more statically,
and treat our static analysis tools better, but that might not be the spirit
of Ruby somehow.

Alternatively, it would be great to do this static type checking
dynamically... I mean, in the runtime rather than compile time. This
means it would be much more accurate, just like those asserts in the
above examples.

However, if we're doing those checks in a hot path, for example, right
inside a loop looping over a million times, this would definitely slow
things down if we're checking them in the runtime. Even if we put `$DEBUG`
guards around those check, we're still suffering from checking the flag.

It would be great if we could actually just remove those checks in
production, while turn it on when we're developing or debugging.
Muack could actually fulfill this desire, as it could inject codes
externally and seamlessly, and we could remove them anytime when we
call `Muack.reset`, or, simply don't do any stubs in production config.

Consider we have two classes:

```  ruby
Food = Class.new
User = Class.new(Struct.new(:food))
```

And we could make sure User#food is always a kind of `Food` by putting this
into a development config or so:

```  ruby
Muack::API.module_eval do
  any_instance_of(User) do |user|
    stub(user).food = is_a(Food)
  end
end
```

And then if we're trying to set a food other than a `Food`...

```  ruby
u, f = User.new, Food.new
u.food = f # ok
u.food = 1 # raise Muack::Unexpected
```

This could go wild and we could customize our own domain specific argument
verifiers. For example, we could do this to check if the food is frozen:

``` ruby
Food = Class.new
User = Class.new(Struct.new(:food))

FoodFrozen = Class.new(Muack::Satisfying) do
  def match actual_arg
    actual_arg.frozen?
  end
end

Muack::API.module_eval do
  any_instance_of(User) do |user|
    stub(user).food = FoodFrozen.new
  end
end

u = User.new
p u.food = Food.new.freeze # ok
p u.food = Food.new        # raise Muack::Unexpected
```

Please check _Arguments Verifiers (Satisfying)_ section for more argument
verifiers details.

[dm-core]: https://github.com/datamapper/dm-core
[ruby-lint]: https://github.com/YorickPeterse/ruby-lint

#### Why didn't mocks nor stubs check if the injected method exists before?

Long story short. I can't find a set of good APIs along with good
implementation. My ideal APIs would be that for mocks and stubs, they
do check if the injected methods exist before, and if we don't want
that check, we use `fake` instead of `mock` or `stub`.

However, how do we specify if `fake` should act like `mock` or `stub`?
Introducing yet another name would make the terms even more confusing
(which are already fairly confusing!), and I don't want something like:
`fake.mock` or `mock.fake` or `fake_mock` or `mock_fake`. Using an option
would also raise the other questions.

What if we make `mock.with_any_times` work exactly like `stub` then?
Then we could have `fake.with_any_times` and that would be the stub
version of fake. This should greatly reduce the complexity and confusion.
However this won't work well because stub is not just mock without times.
They are different in:

* Mocked methods are called in FIFO (queue) order
* Stubbed methods are called in FILO (stack) order
* Stubbed methods could do some pattern matching

Of course we could break them though, but do we really have to, just for
this simple feature? Also, it could be pretty challenging to implement
existing method checking for `any_instance_of`.

If you could find a good set of APIs while implementing it nicely, please
do let me know. Compatibility is not an issue. We could always bump the
major number to inform this incompatibility. I am open to breaking legacy.
Or, I am happy to break legacy.

## USERS:

* [Rib][]
* [rest-core](https://github.com/godfat/rest-core)
* [rest-more](https://github.com/godfat/rest-more)

## CONTRIBUTORS:

* Lin Jen-Shin (@godfat)

## LICENSE:

Apache License 2.0 (Apache-2.0)

Copyright (c) 2013-2022, Lin Jen-Shin (godfat)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
