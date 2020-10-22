
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
