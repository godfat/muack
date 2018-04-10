
require 'muack/test'

describe 'retain visibility' do
  after do
    expect(Muack.verify).eq true
  end

  def verify obj, visibility
    expect(Muack.verify).eq true

    if visibility == :public
      expect(obj).respond_to? :hello
    else
      expect(obj).not.respond_to? :hello
      expect(obj).respond_to? :hello, true
    end
  end

  def generate visibility
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
      send visibility, :hello
    end

    perform(klass, mod)
  end

  copy :test do
    %i[public protected private].each do |visibility|
      would "stub with #{visibility}" do
        obj = generate(visibility)

        stub(obj).hello{'stubbed'}

        verify(obj, visibility)
      end

      would "stub proxy with #{visibility}" do
        obj = generate(visibility)

        stub(obj).hello

        verify(obj, visibility)
      end
    end
  end

  describe 'prepend on class stub with object' do
    def perform(klass, mod)
      klass.prepend(mod)
      klass.new
    end

    paste :test
  end

  describe 'extend on object stub with object' do
    def perform(klass, mod)
      obj = klass.new
      obj.extend(mod)
      obj
    end

    paste :test
  end

  describe 'include on singleton_class stub with object' do
    def perform(klass, mod)
      obj = klass.new
      obj.singleton_class.include(mod)
      obj
    end

    paste :test
  end

  describe 'prepend on singleton_class stub with object' do
    def perform(klass, mod)
      obj = klass.new
      obj.singleton_class.prepend(mod)
      obj
    end

    paste :test
  end
end
