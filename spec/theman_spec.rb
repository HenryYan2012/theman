require 'spec_helper'

describe Theman::Agency, "instance object" do
  before do
    @instance = ::Theman::Agency.new.instance
  end

  it "should superclass active record" do
    @instance.superclass.should == ActiveRecord::Base 
  end

  it "should have connection" do
    @instance.connection.class.should == ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  end

  it "should have a table name" do
    @instance.table_name.should match /c[0-9]{10}/
  end

  it "should have an ispect method" do
    @instance.inspect.should match /Agent/
  end
end

describe Theman::Agency, "instance methods" do
  it "should downcase and symbolize" do
    Theman::Agency.new.symbolize("STRANGE NAME").should == :strange_name
  end
end

describe Theman::Agency, "basic" do
  before do
    @csv = File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec', 'fixtures', 'temp_one.csv'))
    @agent = ::Theman::Agency.new @csv
    @instance = @agent.instance
  end
  
  it "should have all the records from the csv" do
    @instance.count.should == 4
  end
end

describe Theman::Agency, "sed chomp" do
  before do
    @csv = File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec', 'fixtures', 'temp_two.csv'))
    @agent = ::Theman::Agency.new @csv do |agent|
      agent.seds "-n -e :a -e '1,15!{P;N;D;};N;ba'"
    end
    @instance = @agent.instance
  end
  
  it "should have all the records from the csv" do
    @instance.count.should == 5
  end
end

describe Theman::Agency, "data types" do
  before do
    @csv = File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec', 'fixtures', 'temp_one.csv'))
    @agent = ::Theman::Agency.new @csv do |agent|
      agent.nulls /"N"/, /"UNKNOWN"/, /""/
      agent.table do |t|
        t.date :col_date
        t.boolean :col_four
        t.float :col_five
      end
    end
    @instance = @agent.instance
  end

  it "should create date col" do
    @instance.first.col_date.class.should == Date
  end

  it "should create boolean col" do
    @instance.where(:col_four => true).count.should == 2
  end

  it "should create float col" do
    @instance.where("col_five > 10.0").count.should == 2
  end

  it "should have an array of nulls" do
    @agent.null_replacements.should == [/"N"/, /"UNKNOWN"/, /""/]
  end
  
  it "should have nulls not strings" do
    @instance.where(:col_two => nil).count.should == 2
    @instance.where(:col_three => nil).count.should == 2
  end
end