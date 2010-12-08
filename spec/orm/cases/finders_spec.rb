require 'spec_helper'
require 'orm/models/test_class'
require 'orm/models/person'

describe "finders" do
  describe "#find dry test" do
    include MockMassiveRecordConnection

    before do
      @mocked_table = mock(MassiveRecord::Wrapper::Table).as_null_object
      Person.stub(:table).and_return(@mocked_table)
      
      @row = MassiveRecord::Wrapper::Row.new
      @row.id = "ID1"
      @row.values = { :info => { :name => "John Doe", :age => "29" } }
    end

    it "should have at least one argument" do
      lambda { Person.find }.should raise_error ArgumentError
    end

    it "should ask the table to look up by it's id" do
      @mocked_table.should_receive(:find).with(1).and_return(@row)
      Person.find(1)
    end

    %w(first last all).each do |method|
      it "should call table's #{method} on find(:{method})" do
        @mocked_table.should_receive(method).and_return(@row)
        Person.find(method.to_sym)
      end
    end
  end

  %w(first last all).each do |method|
    it "should respond to #{method}" do
      TestClass.should respond_to method
    end

    it "should delegate #{method} to find with first argument as :#{method}" do
      TestClass.should_receive(:find).with(method.to_sym)
      TestClass.send(method)
    end

    it "should delegate #{method}'s call to find with it's args as second argument" do
      options = {:foo => :bar}
      TestClass.should_receive(:find).with(anything, options)
      TestClass.send(method, options)
    end
  end




  describe "#find database test" do
    before(:all) do
      @connection_configuration = {:host => MR_CONFIG['host'], :port => MR_CONFIG['port']}
      @connection = MassiveRecord::Wrapper::Connection.new(@connection_configuration)
      @connection.open
    end

    before do
      Person.stub!(:table_name).and_return(MR_CONFIG['table'])
      Person.connection_configuration = @connection_configuration
      @table = MassiveRecord::Wrapper::Table.new(@connection, Person.table_name)
      @table.column_families.create(:info)
      @table.save
      
      @row = MassiveRecord::Wrapper::Row.new
      @row.id = "ID1"
      @row.values = {:info => {:name => "John Doe", :email => "john@base.com", :age => "20"}}
      @row.table = @table
      @row.save
    end

    after do
      @table.destroy 
    end

    it "should return nil if id is not found" do
      lambda { Person.find("not_found") }.should raise_error MassiveRecord::ORM::RecordNotFound
    end

    it "should return the person object when found" do
      #pending "Vincent will work at this. Take a look at lib/massive_record/orm/finders.rb. There is a TODO there :-)"
      person = Person.find("ID1")
      person.name.should == "John Doe"
      person.email.should == "john@base.com"
      person.age.should == "20"
    end
  end
end
