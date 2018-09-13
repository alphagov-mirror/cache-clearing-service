require "net/http"
require "lib/govuk_nodes"

class Processor
  def initialize
    @logger = CacheClearingService.config.logger
    @varnish_clearer = VarnishClearer.new(logger)
    @fastly_clearer = FastlyClearer.new(logger)
  end

  def process(message)
    paths_for(content_item: message.payload).each do |path|
      varnish_clearer.clear_for(path)
      fastly_clearer.clear_for(path)
    end

    message.ack
  end

  def paths_for(content_item:)
    routes = content_item.fetch("routes", [])
    redirects = content_item.fetch("redirects", [])

    (routes + redirects)
      .select { |route| route.fetch("type") == "exact" }
      .map { |route| route.fetch("path") }
  end

private

  attr_reader :fastly_clearer, :logger, :varnish_clearer
end