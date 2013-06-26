# CHANGES

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
