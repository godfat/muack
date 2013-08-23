# CHANGES

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
