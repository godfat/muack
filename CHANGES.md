# CHANGES

## Muack 1.7.0 -- 2022-12-29

### Incompatible changes

* Drop support for Ruby 2.6-

### Bugs fixed

* Fixed stubbed instance method not following the original visibility.
  It's always public before this fix.
* Worked around a few JRuby 9.4 compatibility issues. Note that there are
  still some issues due to JRuby bugs. Those tests are currently skipped.

## Muack 1.6.0 -- 2020-12-06

### Enhancement

* Fix a few cases for mocking against modules/classes with prepended modules,
  especially when `any_instance_of` is also used in combination. Previously,
  it's either not mocking correctly or it may affect modules/classes which
  also use the same prepended modules. For mocking prepended methods, an
  internal `MuackPrepended` module will be prepended into the modules/classes
  to properly override the prepended methods. This module cannot be removed
  between tests because there's no way to do that with current Rubies.
* Performance could be potentially slightly improved with Ruby 2.6+

## Muack 1.5.1 -- 2020-12-06

### Bugs fixed

* Eliminated potential keyword arguments warnings for `initialize` when
  mocking against `new`.

## Muack 1.5.0 -- 2020-11-28

### Bugs fixed

* Properly handle prepended objects
* Properly restore method visibilities for singleton methods

### Enhancement

* Eliminated any potential keyword arguments warnings to be future proof
* Some major internal restructure

## Muack 1.4.0 -- 2015-11-21

### Incompatible changes / Enhancement

* Spies would now do pattern matching like stubs for matching
  method arguments. This could be an incompatible change if you're
  relying on spies checking the order for the same method calls.
  This change would make spies and stubs more similar. If you are
  really into a specific order, use mocks instead.

## Muack 1.3.2 -- 2015-06-11

* Fixed a bug for `where`, `having`, and `allowing` which should distinguish
  between `nil` and `undefined` (which does not have a key in a hash)

## Muack 1.3.1 -- 2015-05-27

* Fixed a bug for `where`, `having`, and `allowing` which would raise an
  exception whenever the actual value is not a hash or array.

## Muack 1.3.0 -- 2015-05-24

### Incompatible changes

* `Muack::API.match` is renamed to `Muack::API.matching`
* `Muack::API.respond_to` is renamed to `Muack::API.responding_to`
* `Muack::API.hash_including` is renamed to `Muack::API.having`
* `Muack::API.satisfy` is renamed to `Muack::API.satisfying`
* `Muack::Satisy` is renamed to `Muack::Satisying`

### Enhancement

* `Muack::API.where` is added
* `Muack::API.allowing` is added

## Muack 1.2.0 -- 2015-03-10

* Now stubs could be overwritten. Input from @mz026

## Muack 1.1.2 -- 2014-11-07

* Introduced `Muack::API.coat`.
  See [README.md](README.md#coats) for explanation.

* `Muack::Session` is no longer a hash. Hope no one is trying to store
   anything into it so this change would break nothing.

* `Muack::Failure` is no longer an Exception, but a StandardError.

## Muack 1.1.1 -- 2014-05-21

It's no longer necessary to make spy the last call. Below now works:

``` ruby
obj = Object.new
stub(obj).say{}
2.times do
  obj.say
  spy(obj).say
end
```

Previously, only this works:

``` ruby
obj = Object.new
stub(obj).say{}
2.times{ obj.say }
2.times{ spy(obj).say }
```

This would be very useful when using Muack with [RubyQC][], in which cases
we don't know how many times the spied object would be called.

[RubyQC]: https://github.com/godfat/rubyqc

## Muack 1.1.0 -- 2014-04-17

Improvements:

* Now we show "Unexpected call" instead of "Expected ... was not called".
  This should make it easier to read and understand.

Incompatible changes:

* Previously, if you're using a spy, it would examine all the messages for
  the given stub. However this might not be desired as then we need to
  specify everything in the stub for the spy. Tedious. From now on, spies
  would only examine specified messages, ignoring unspecified stubbed
  methods. This sort of breaks the concept that "mocks = stubs + spies"
  as spies would not fully examine the stubs now. It's now more like:
  "mocks >= stubs + spies".

## Muack 1.0.4 -- 2014-03-29

* Now we could `Muack.verify(obj)` or `Muack.reset(obj)` a single object.

## Muack 1.0.3 -- 2014-03-11

* From now on, `Muack::API.hash_including` could accept `Muack::Satisfy` as
  values. That means we could now use `hash_including(:key => is_a(String))`
  or `hash_including(:url => match(/^https/))` and so on so forth.

## Muack 1.0.2 -- 2014-01-17

* Fixed a bug where spies do not really verify against actual arguments,
  but the definition from stubs. This might make stubs a bit slower as
  now it needs to really create objects storing actual arguments.
  Previously, it only reused its definitions thus no objects were created.

## Muack 1.0.1 -- 2014-01-07

* Fixed a regression where proxy with multiple arguments might not pass
  all arguments along.

## Muack 1.0.0 -- 2014-01-06

Improvements:

* The internal conflicting method names are now a bit more informative
  and unique thus less likely to have conflicts.

* Fixed a bug where mock and stub with the same method were defined.
  Previously, it would raise an undefined method error upon verifying
  while we're removing injected method. Now it could properly undefine
  injected methods.

* Fixed issues mocking private methods. Now it would not only work without
  a problem, but also preserve the privilege if the original method is a
  private method. Note that for now, protected methods are treated as
  public methods though.

* Fixed a bug where user customized Satisfy could crash if it's located
  on a top-level. i.e. class names without ::.

Incompatible changes:

* Removed proxy method. From now on, if you do not pass a block to a
  mock, then it would assume it's a proxy. You can think of instead of
  make an empty block as a default, the original method is the default.
  That means, previously, mock without a block would always return nil,
  but now it instead means a proxy.

* Introduced peek_args method. Sometimes I really need to peek the
  arguments of a method, or trying to provide a different argument
  based on the original argument. So peek_args is the way to do it.

* Introduced peek_return method. By duality, we also introduce something
  we can peek the return value. Using this along with a custom block
  doesn't really make sense, but this is actually the previous proxy
  block. Previously, if a mock is a proxy, then the block doesn't really
  mean the implementation, but a modification to the original return.
  That is, the current peek_return. Originally the block is quite
  inconsistent as the semantics of the block would change depending on
  it is a proxy or not.

So to proxy the to_s method and then reverse the result, you write:

``` ruby
str = 'str'
Muack::API.mock(str).to_s.peek_return{ |s| s.reverse }
p str.to_s # => 'rts'
```

* Removed plain value argument in `returns`. From now on, we should
  always use the block form. Instead, the argument was changed to be
  an optional option for specifying if the underlying block should be
  instance executed or not. By default, the block is lexical scoped.
  If passing `:instance_exec => true` to `returns`, `peek_args`, and
  `peek_return`, then the block is instead instance scoped, passing
  to the instance's `instance_exec`. This way, we would be able to
  touch the inside of mocked object.

Without passing `:instance_exec => true`, `to_i` would be called on
the top-level object instead. By passing this argument, `to_i` would be
called in the string.

``` ruby
str = '123'
Muack::API.mock(str).int.returns(:instance_exec => true){to_i}
p str.int # => 123
```

## Muack 0.7.3 -- 2013-10-01

* Added `Muack::API.including(element)` for detecting if the underlying
  element is included in the passed argument.

## Muack 0.7.2 -- 2013-08-23

* Show correct Expected error for special satisfiers. Previously, it would
  incorrectly showing Unexpected error. However it's considered expected,
  it's simply the number of times is wrong.

## Muack 0.7.1 -- 2013-07-13

* Added `respond_to` argument matcher corresponding to RR's duck_type.
* Added `|` and `&` for argument matcher union and intersection. See README.md

## Muack 0.7.0 -- 2013-06-27

### Incompatible changes

* Now instead of using mock_proxy, we use `proxy` as a modifier. That says
  mock_proxy and stub_proxy no longer existed. like this:

``` ruby
mock(object).to_s.proxy
stub(object).to_s.proxy
```

We change this due to the introduction of spies.

### Enhancement

* We have spies support now. Here's an example:

``` ruby
subject = Object.new
stub(subject).foo(1)
subject.foo(1)

spy(subject).foo(1)
spy(subject).bar # This doesn't verify immediately.
Muack.verify     # This fails, saying `bar` was never called.
```

* It would now raise a `StubHasNoTimes` exception if you tried to set times
  on stubs, which has no meanings in Muack. Use `mock` or `spy` instead if
  you need to specify times.

* Muack.reset and Muack.verify is now thread-safe.
  You can run test cases concurrently now.

* AnyInstanceOf now has a more readable inspect.
* Improved various error messages. e.g. CannotFindInjectionName.
* You can now set ENV['MUACK_RECURSION_LEVEL'] to raise the limit
  to find a new method name when we're injecting a method. Normally
  this should not happen, and it could be a bug in Muack. But instead of
  putting a magic number 9 out there as before, this might be better.

## Muack 0.5.2 -- 2013-06-26

* Add `returns` modifier which you can pass the return values if passing
  a block to a certain method is not convenient (e.g. `[]`).

Instead of sending `method_missing` to pass a block:

``` ruby
stub(object).method_missing(:[], is_a(Fixnum)){ |a| a+1 }
object[1]  #=> 2
```

You could now use `returns` to pass the block.

``` ruby
stub(object)[is_a(Fixnum)].returns{ |a| a + 1 }
object[1]  #=> 2
```

Or if you only want to return a simple value, you could also pass the
value directly without passing a block:

``` ruby
stub(object)[is_a(Fixnum)].returns(2)
object[1]  #=> 2
```

## Muack 0.5.1 -- 2013-06-25

* Fix issues with multiple call to any_instance_of with the same class.
* any_instance_of now accepts a block as mock and others.
* Fixed various bugs for dispatching methods with proxy and any_instance_of.

## Muack 0.5.0 -- 2013-06-24

* Birthday!
