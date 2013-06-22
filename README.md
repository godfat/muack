# Muack

by Lin Jen-Shin ([godfat](http://godfat.org))

## LINKS:

* [github](https://github.com/godfat/muack)
* [rubygems](https://rubygems.org/gems/muack)
* [rdoc](http://rdoc.info/github/godfat/muack)

## DESCRIPTION:

Muack -- Yet Another Mocking Library

Basically it's an RR clone.

## REQUIREMENTS:

* Tested with MRI (official CRuby) 1.9.3, 2.0.0, Rubinius and JRuby.

## INSTALLATION:

    gem install muack

## SYNOPSIS:

Basically it's an [RR](https://github.com/rr/rr) clone. Let's see a
[bacon](https://github.com/chneukirchen/bacon) example.

``` ruby
require 'bacon'
require 'muack'

include Muack::API

describe 'Hello' do
  after do
    Muack.verify
  end

  should 'say world!' do
    str = 'Hello'
    mock(str).say('!'){ |arg| "World#{arg}" }
    str.say('!').should.equal 'World!'
  end
end
```

More recipes to come.

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
