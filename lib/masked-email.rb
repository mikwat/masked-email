require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'optparse'

class MaskedEmail
  BASE_URL = 'https://api.fastmail.com/'
  API_KEY_FILE = File.expand_path('~/.fastmail-api-key')

  SET_METHOD = 'MaskedEmail/set'
  MASKEDEMAIL = 'https://www.fastmail.com/dev/maskedemail'
  APPLICATION_JSON_CONTENT_TYPE = 'application/json; charset=utf-8'

  class << self
    def run
      options = parse_options
      validate_options(options)

      api_token = api_credentials(options)

      url = URI(BASE_URL)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      session = fetch_session_map(api_token)
      account_id = session['primaryAccounts'][MASKEDEMAIL]
      api_url = session['apiUrl']

      exit if options[:dry_run]

      # create masked email
      method_id = 'k1'
      json = create_masked_email(api_token, account_id, api_url, method_id)
      methodResponse = json['methodResponses'].find { _1[0] == method }
      email = methodResponse[1]['created'][method_id]['email']
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
      elsif File.exist?(API_KEY_FILE)
        IO.readlines(API_KEY_FILE).first.chomp
      else
        puts 'No credentials found, see --help'
        exit(1)
      end
    end

    # fetch account information
    def fetch_session_map(api_token)
      url = URI("#{BASE_URL}jmap/session")
      request = Net::HTTP::Get.new(url)
      request['Content-Type'] = APPLICATION_JSON_CONTENT_TYPE
      request["Authorization"] = "Bearer #{api_token}"
      response = http.request(request)
      body = response.read_body
      puts body if options[:verbose]

      JSON.parse(body)
    end

    def create_masked_email(api_token, account_id, api_url, method_id)
      request = Net::HTTP::Post.new(api_url)
      request['Content-Type'] = APPLICATION_JSON_CONTENT_TYPE
      request['Authorization'] = "Bearer #{api_token}"
      request.body = {
        using: [MASKEDEMAIL],
        methodCalls: [
          [
            SET_METHOD,
            {
              accountId: account_id,
              create: {
                method_id => {
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

      JSON.parse(body)
    end
  end
end
