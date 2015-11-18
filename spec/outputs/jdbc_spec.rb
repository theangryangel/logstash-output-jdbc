require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/jdbc"
require "stud/temporary"

describe LogStash::Outputs::Jdbc do

  it "should register without errors" do
    plugin = LogStash::Plugin.lookup("output", "jdbc").new({})
    expect { plugin.register }.to_not raise_error
    
  end
  
end
