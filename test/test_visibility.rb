
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

  describe 'set the same visibility from the original method' do
    copy :test do
      def find_visibilities
        %i[public protected private].map do |v|
          object.send("#{v}_methods").include?(:hello)
        end
      end

      would do
        current_visibilities = find_visibilities

        stub(object).hello{ :stub }

        expect(find_visibilities).eq current_visibilities
      end
    end

    describe 'for instance method' do
      def object
        @object ||= Class.new do
          private
          def hello; :hello; end
        end.new
      end

      paste :test
    end

    describe 'for singleton method' do
      def object
        @object ||= begin
          ret = Object.new
          def ret.hello; :hello; end
          ret
        end
      end

      paste :test
    end
  end

  # Brought from rspec-mocks
  would "correctly restore the visibility of methods whose visibility has been tweaked on the singleton class" do
    # JRuby didn't store the visibility change on the singleton class,
    # therefore it cannot be properly detected and visibility change
    # will be lost upon reset.
    skip if RUBY_ENGINE == 'jruby'

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
