# frozen_string_literal: true

require 'spec_helper'
require 'simplekiq/throttle_fetch'

RSpec.describe Simplekiq::ThrottleFetch do
  subject { described_class.new(queues: %w[a b c]) }

  describe 'everything' do
    it 'needs test coverage' do
      expect(true).to be(false)
    end
  end
end
