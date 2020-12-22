
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
    klass = Class.new

    mod = Module.new do
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

  # Brought from rspec-mocks
  would "correctly restore the visibility of methods whose visibility has been tweaked on the singleton class" do
    # hello is a private method when mixed in, but public on the module
    # itself
    mod = Module.new do
      extend self
      def hello; :hello; end

      private :hello
      class << self; public :hello; end
    end

    expect(mod.hello).eq :hello

    stub(mod).hello{ :stub }

    Muack.reset

    expect(mod.hello).eq :hello
  end
end
