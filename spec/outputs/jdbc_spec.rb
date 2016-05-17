require_relative '../jdbc_spec_helper'

describe LogStash::Outputs::Jdbc do
  context 'when initializing' do
    it 'shouldn\'t register without a config' do
      expect do
        LogStash::Plugin.lookup('output', 'jdbc').new
      end.to raise_error(LogStash::ConfigurationError)
    end
  end
end
