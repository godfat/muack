
require 'muack/test'

describe 'mock with prepend' do
  after do
    verify
  end

  def verify
    expect(Muack.verify).eq true
  end

  copy :test do
    would 'mock with prepend' do
      obj = generate

      mock(obj).hello{'mocked'}

      expect(obj.greet).eq 'mocked'
      verify
      expect(obj.greet).eq 'hello'
    end

    would 'mock proxy with prepend' do
      obj = generate

      mock(obj).hello

      expect(obj.greet).eq 'hello'
      verify
      expect(obj.greet).eq 'hello'
    end
  end

  describe 'prepend on class mock with object' do
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
      end

      klass.prepend(mod)
      klass.new
    end

    paste :test
  end

  describe 'extend on object mock with object' do
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
      end

      obj = klass.new
      obj.extend(mod)
      obj
    end

    paste :test
  end

  describe 'include on singleton_class mock with object' do
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
      end

      obj = klass.new
      obj.singleton_class.include(mod)
      obj
    end

    paste :test
  end

  describe 'prepend on singleton_class mock with object' do
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
      end

      obj = klass.new
      obj.singleton_class.prepend(mod)
      obj
    end

    paste :test
  end
end
