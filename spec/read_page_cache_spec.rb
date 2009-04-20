require 'spec_helper'
require 'ruby-debug'
require 'open-uri'

TMPDIR = File.join(File.dirname(__FILE__), '../tmp')
Dir.mkdir(TMPDIR) unless File.exist?(TMPDIR)

TEST_DATA = "Testing cache read"

describe "ReadPageCache" do

  after(:each) do
    Dir.glob(File.join(TMPDIR, '*')).each {|f| File.delete(f) if File.exist?(f)}
  end

  it 'should add read_page method to a class' do
    class A
    end
    # attach to the class then create instance
    ReadPageCache.attach_to A, TMPDIR
    a = A.new
    a.respond_to?('read_page').should be_true
  end

  it 'should add read_page method to a class not the instance' do
    class A
    end
    # create instance then attach to the class
    a = A.new
    ReadPageCache.attach_to A, TMPDIR
    a.respond_to?('read_page').should be_true
  end

  # this is not nice but we make a web access to www.example.com
  # just to get a response to cache.  There probably is a better
  # website to do this to.
  it 'should override the read_page method in a class' do
    class A
      def read_page(page)
        open(page).read
      end
    end
    ReadPageCache.attach_to A, TMPDIR
    a = A.new
    a.read_page('http://www.example.com/')
    filespec = File.join(TMPDIR, 'www.example.com.html')
    (File.exist?(filespec).should be_true) && (File.size(filespec).should > 0)
  end

  it 'should read from the cache' do
    filespec = File.join(TMPDIR, 'www.example.com.html')
    File.open(filespec, "w") {|f| f.puts TEST_DATA}

    class A
      def read_page(page)
        open(page).read
      end
    end
    ReadPageCache.attach_to A, TMPDIR
    a = A.new
    data = a.read_page('http://www.example.com/').strip
    data.should == TEST_DATA
  end

  it 'should replace all read_page methods in all classes' do
    # create two classes with read_page methods
    class A
      def read_page(page)
        open(page).read
      end
    end
    class B
      def read_page(page)
        open(page).read
      end
    end
    # when we attach to the class, ReadPageCache also puts a _cache_file method
    # into the class, so we can simply test for it's presence.
    ReadPageCache.attach_to_classes(TMPDIR)
    a = A.new
    b = B.new
    (a.respond_to?('_cache_file').should be_true) && (b.respond_to?('_cache_file').should be_true)
  end

end
