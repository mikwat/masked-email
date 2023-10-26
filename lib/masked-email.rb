require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'optparse'

class MaskedEmail
  BASE_URL = 'https://api.fastmail.com/'

  class << self
    def run
      options = parse_options
      validate_options(options)

      api_token = api_credentials(options)

      # determine masked email api url
      url = URI("#{BASE_URL}jmap/session")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request['Content-Type'] = 'application/json; charset=utf-8'
      request["Authorization"] = "Bearer #{api_token}"
      response = http.request(request)
      body = response.read_body
      puts body if options[:verbose]

      exit if options[:dry_run]

      json = JSON.parse(body)
      accountId = json['primaryAccounts']['https://www.fastmail.com/dev/maskedemail']
      apiUrl = json['apiUrl']

      # create masked email
      method = 'MaskedEmail/set'
      methodId = 'k1'
      request = Net::HTTP::Post.new(apiUrl)
      request['Content-Type'] = 'application/json; charset=utf-8'
      request['Authorization'] = "Bearer #{api_token}"
      request.body = {
        using: ['https://www.fastmail.com/dev/maskedemail'],
        methodCalls: [
          [
            method,
            {
              accountId: accountId,
              create: {
                methodId => {
                  state: 'enabled',
                  forDomain: options[:domain]
                }
              }
            },
            'a'
          ]
        ]
      }.to_json
      response = http.request(request)
      body = response.read_body
      puts body if options[:verbose]

      json = JSON.parse(body)
      methodResponse = json['methodResponses'].find { _1[0] == method }
      email = methodResponse[1]['created'][methodId]['email']
      puts "Masked email created: #{email}"
    end

    private

    # parse command-line options
    def parse_options
      options = {}
      OptionParser.new do |parser|
        parser.banner = 'Usage: masked-email [options]'

        parser.on('-d', '--domain DOMAIN', 'Domain to create email for') do |d|
          options[:domain] = d
        end

        parser.on('-c', '--credentials FILE', 'Credentials file') do |c|
          options[:credentials] = c
        end

        parser.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
          options[:verbose] = v
        end

        parser.on('', '--dry-run', 'Dry run') do |dr|
          options[:dry_run] = dr
        end

        parser.on('-h', '--help', 'Prints this help') do
          puts parser
          exit
        end

      end.parse!

      options
    end

    def validate_options(options)
      if options[:domain].nil?
        puts 'Domain required, see --help'
        exit(1)
      end

      unless URI::regexp.match?(options[:domain])
        puts 'Domain must be valid URI'
        exit(1)
      end
    end

    def api_credentials(options)
      if options[:credentials]
        IO.readlines(options[:credentials]).first.chomp
      elsif ENV['FASTMAIL_API_KEY']
        ENV['FASTMAIL_API_KEY']
      else
        puts 'No credentials provided'
        exit(1)
      end
    end
  end
end

