require 'octokit'
require 'uri'
require 'optparse'

TOKEN = ARGV[0]
fail ArgumentError, 'Authentication token is required' unless TOKEN

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: ruby github_repos.rb [options]'

  opts.on('-o', '--org ORG', 'Organization to backup') do |org|
    options[:org] = org
  end
end.parse!

class Fetcher
  attr_reader :token, :options, :known_repos
  def initialize(token, options)
    @token = token
    @options = options
    @known_repos = []
  end

  def fetch_and_print
    if options[:org]
      org = client.org(options[:org])

      paginate_and_print_unique_repos(client.get(org.rels[:repos].href))
    else
      paginate_and_print_unique_repos(client.repos)

      client.orgs.each do |org|
        paginate_and_print_unique_repos(client.get(org.rels[:repos].href))
      end
    end
  end

  private

  def paginate_and_print_unique_repos(data)
    paginate(data, client) do |repos|
      repos = repos.map(&:clone_url)
      new_repos = repos - known_repos
      new_repos.each { |url| puts add_auth_to_url(url) }
      @known_repos += new_repos
    end
  end

  def paginate(data, client, &block)
    yield(data)

    if next_page = client.last_response.rels[:next]
      paginate(client.get(next_page.href), client, &block)
    end
  end

  def client
    @client ||= Octokit::Client.new(access_token: token)
  end

  def add_auth_to_url(url)
    uri = URI(url)
    uri.user = token
    uri.to_s
  end
end

Fetcher.new(TOKEN, options).fetch_and_print
