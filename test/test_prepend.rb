
require 'muack/test'

describe 'mock with prepend' do
  after do
    verify
  end

  def verify
    expect(Muack.verify).eq true
  end

  def generate
    klass = Class.new do
      def greet
        'hi'
      end
    end

    mod = Module.new do
      def greet
        hello
      end

      def hello
        'hello'
      end
      private :hello
    end

    perform(klass, mod)
  end

  copy :test do
    would 'mock' do
      obj = generate

      mock(obj).hello{'mocked'}

      expect(obj.greet).eq 'mocked'
      verify
      expect(obj.greet).eq 'hello'
      expect(obj).not.respond_to? :hello
    end

    would 'mock proxy' do
      obj = generate

      mock(obj).hello

      expect(obj.greet).eq 'hello'
      verify
      expect(obj.greet).eq 'hello'
      expect(obj).not.respond_to? :hello
    end
  end

  describe 'prepend on class mock with object' do
    def perform(klass, mod)
      klass.prepend(mod)
      klass.new
    end

    paste :test
  end

  describe 'extend on object mock with object' do
    def perform(klass, mod)
      obj = klass.new
      obj.extend(mod)
      obj
    end

    paste :test
  end

  describe 'include on singleton_class mock with object' do
    def perform(klass, mod)
      obj = klass.new
      obj.singleton_class.include(mod)
      obj
    end

    paste :test
  end

  describe 'prepend on singleton_class mock with object' do
    def perform(klass, mod)
      obj = klass.new
      obj.singleton_class.prepend(mod)
      obj
    end

    paste :test
  end

  describe 'class with a chain of prepended modules' do
    would 'not affect other modules' do
      mod0 = Module.new{ def f; :m0; end }
      mod1 = Module.new{ def f; :m1; end }
      klass0 = Class.new{ prepend mod0 }
      klass1 = Class.new{ prepend mod1 }
      klass = Class.new{ prepend mod1; prepend mod0 }

      mock(any_instance_of(klass)).f{:f}

      expect(klass.new.f).eq :f
      expect(klass0.new.f).eq :m0
      expect(klass1.new.f).eq :m1
    end
  end

  describe 'class and subclass' do
    would 'work for prepended superclass' do
      mod = Module.new{ def f; :f; end }
      base = Class.new{ prepend mod }
      sub = Class.new(base)

      mock(any_instance_of(base)).f{:g}.times(2)

      expect(base.new.f).eq :g
      expect(sub.new.f).eq :g
    end
  end

  # Brought from rspec-mocks and it's currently failing on rspec-mocks
  # See https://github.com/rspec/rspec-mocks/pull/1218
  would "handle stubbing prepending methods that were only defined on the prepended module" do
    to_be_prepended = Module.new do
      def value
        "#{super}_prepended".to_sym
      end

      def value_without_super
        :prepended
      end
    end

    object = Object.new
    object.singleton_class.send(:prepend, to_be_prepended)
    expect(object.value_without_super).eq :prepended

    stub(object).value_without_super{ :stubbed }

    expect(object.value_without_super).eq :stubbed

    expect(Muack.verify)
    expect(object.value_without_super).eq :prepended
  end
end
