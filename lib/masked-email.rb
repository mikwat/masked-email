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

  def initialize
    url = URI(BASE_URL)
    @http = Net::HTTP.new(url.host, url.port)
    @http.use_ssl = true
  end

  def run
    parse_options
    validate_options
    setup_api_token

    session = fetch_session_map
    account_id = session['primaryAccounts'][MASKEDEMAIL]
    api_url = session['apiUrl']

    exit if @options[:dry_run]

    # create masked email
    method_id = 'k1'
    response = create_masked_email(account_id, api_url, method_id)
    method_response = response['methodResponses'].find { _1[0] == SET_METHOD }
    email = method_response[1]['created'][method_id]['email']
    puts "Masked email created: #{email}"
  end

  private

  # parse command-line options
  def parse_options
    @options = {}
    OptionParser.new do |parser|
      parser.banner = 'Usage: masked-email [options]'

      parser.on('-d', '--domain DOMAIN', 'Domain to create email for') do |d|
        @options[:domain] = d
      end

      parser.on('-c', '--credentials FILE', 'Credentials file') do |c|
        @options[:credentials] = c
      end

      parser.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
        @options[:verbose] = v
      end

      parser.on('', '--dry-run', 'Dry run') do |dr|
        @options[:dry_run] = dr
      end

      parser.on('-h', '--help', 'Prints this help') do
        puts parser
        exit
      end

    end.parse!

    @options
  end

  def validate_options
    if @options[:domain].nil?
      puts 'Domain required, see --help'
      exit(1)
    end

    unless URI::regexp.match?(@options[:domain])
      puts 'Domain must be valid URI'
      exit(1)
    end
  end

  def setup_api_token
    @api_token =
      if @options[:credentials]
        IO.readlines(@options[:credentials]).first.chomp
      elsif ENV['FASTMAIL_API_KEY']
        ENV['FASTMAIL_API_KEY']
      elsif File.exist?(API_KEY_FILE)
        IO.readlines(API_KEY_FILE).first.chomp
      else
        raise 'No credentials found, see --help'
      end
  end

  # fetch account information
  def fetch_session_map
    url = URI("#{BASE_URL}jmap/session")
    request = Net::HTTP::Get.new(url)
    request['Content-Type'] = APPLICATION_JSON_CONTENT_TYPE
    request["Authorization"] = "Bearer #{@api_token}"
    response = @http.request(request)
    body = response.read_body
    puts body if @options[:verbose]

    JSON.parse(body)
  end

  def create_masked_email(account_id, api_url, method_id)
    request = Net::HTTP::Post.new(api_url)
    request['Content-Type'] = APPLICATION_JSON_CONTENT_TYPE
    request['Authorization'] = "Bearer #{@api_token}"
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
                forDomain: @options[:domain]
              }
            }
          },
          'a'
        ]
      ]
    }.to_json
    response = @http.request(request)
    body = response.read_body
    puts body if @options[:verbose]

    JSON.parse(body)
  end
end
