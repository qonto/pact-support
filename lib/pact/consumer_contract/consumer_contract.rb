require 'pact/logging'
require 'pact/something_like'
require 'pact/symbolize_keys'
require 'pact/term'
require 'pact/shared/active_support_support'
require 'date'
require 'json/add/regexp'
require 'open-uri'
require 'pact/consumer_contract/service_consumer'
require 'pact/consumer_contract/service_provider'
require 'pact/consumer_contract/interaction'
require 'pact/consumer_contract/pact_file'
require 'pact/consumer_contract/http_consumer_contract_parser'

module Pact

  class ConsumerContract

    include SymbolizeKeys
    include Logging
    include PactFile

    attr_accessor :interactions
    attr_accessor :consumer
    attr_accessor :provider

    def initialize(attributes = {})
      @interactions = attributes[:interactions] || []
      @consumer = attributes[:consumer]
      @provider = attributes[:provider]
    end

    def self.add_parser consumer_contract_parser
      parsers.unshift(consumer_contract_parser)
    end

    def self.parsers
      @parsers ||= [Pact::HttpConsumerContractParser.new]
    end

    def self.from_hash(hash)
      parsers.each do | parser |
        return parser.call(hash) if parser.can_parse?(hash)
      end
      raise Pact::Error.new("No consumer contract parser found for hash: #{hash}")
    end

    def self.from_json string
      deserialised_object = JSON.load(maintain_backwards_compatiblity_with_producer_keys(string))
      from_hash(deserialised_object)
    end

    def self.from_uri uri, options = {}
      from_json(Pact::PactFile.read(uri, options))
    end

    def self.maintain_backwards_compatiblity_with_producer_keys string
      string.gsub('"producer":', '"provider":').gsub('"producer_state":', '"provider_state":')
    end

    def find_interaction criteria
      interactions = find_interactions criteria
      if interactions.size == 0
        raise Pact::Error.new("Could not find interaction matching #{criteria} in pact file between #{consumer.name} and #{provider.name}.")
      elsif interactions.size > 1
        raise Pact::Error.new("Found more than 1 interaction matching #{criteria} in pact file between #{consumer.name} and #{provider.name}.")
      end
      interactions.first
    end

    def find_interactions criteria
      interactions.select{ | interaction| interaction.matches_criteria?(criteria)}
    end

    def each
      interactions.each do | interaction |
        yield interaction
      end
    end

  end
end
