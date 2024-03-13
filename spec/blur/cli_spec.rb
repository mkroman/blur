# frozen_string_literal: true

describe Blur::CLI do
  describe '#parse!' do
    context 'args: -V' do
      let(:args) { ['-V'] }

      it 'should print blur version and exit' do
        expect { subject.parse!(args) }.to output(Blur::VERSION).to_stdout
      end
    end
  end
end
