require_relative "../jdbc_spec_helper"

describe LogStash::Outputs::Jdbc do
  context 'when initializing' do

    it 'shouldn\'t register without a config' do
      expect { 
        LogStash::Plugin.lookup("output", "jdbc").new()
      }.to raise_error(LogStash::ConfigurationError)
    end

  end
end
