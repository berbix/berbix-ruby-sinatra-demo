require 'sinatra'
require 'sinatra/reloader' if development?
require 'yaml'
require 'berbix'
require 'namey'
require 'json'
require 'sinatra/custom_logger'
require 'logger'

set :logger, Logger.new(STDOUT)

berbix_config = YAML.load(File.read('berbix_config.yaml'))

get '/' do
  @generator = Namey::Generator.new
  @username = @generator.name(:common)
  
  if params[:uid]
    @uid = params[:uid]
  else
    @uid = 123
  end

  client = Berbix::Client.new(
    client_secret: berbix_config['client_secret'],
    environment: :production
  )

  # Check if refresh token exists for given UID
  if File.file?("#{@uid}_refresh_token.txt")
    # read the refresh token from disk
    @refresh_token = File.open("#{@uid}_refresh_token.txt").read
    
    begin
      @transaction_tokens = Berbix::Tokens.from_refresh(@refresh_token)
      @data = client.fetch_transaction(@transaction_tokens) # needed to force library to refresh the refresh token
    rescue => exception
      @transaction_tokens = nil
    end
  end    
    
  if @transaction_tokens.nil?
    @transaction_tokens = client.create_transaction(
      customer_uid: @uid, # ID for the user in client database
      template_key: berbix_config['template_key'], # Template key for this transaction
      hosted_options: {}
    )
    File.open("#{@uid}_refresh_token.txt", "w") do |file|
      file.write(@transaction_tokens.refresh_token)
    end
  end

  erb :index
end

get '/after_id_check' do
  @refresh_token = File.open('./refresh_token.txt', &:readline).gsub(/\s+/, "")

  client = Berbix::Client.new(
    client_secret: berbix_config['client_secret'],
    environment: :production
  )

  transaction_tokens = Berbix::Tokens.from_refresh(@refresh_token)

  @data = client.fetch_transaction(transaction_tokens)

  @name_on_id = @data["fields"]["given_name"]["value"] + " " + @data["fields"]["family_name"]["value"]

  @name_match = @name_on_id.casecmp?(params[:username])

  erb :after_id_check
end