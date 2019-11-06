require 'sinatra'
require 'sinatra/reloader' if development?
require 'yaml'
require 'berbix'
require 'namey'

berbix_config = YAML.load(File.read('berbix_config.yaml'))

get '/' do
  @generator = Namey::Generator.new
  @username = @generator.name(:common)
  @uid = rand(10000000000)

  client = Berbix::Client.new(
    client_secret: berbix_config['client_secret'],
    environment: :production
  )

  @transaction_tokens = client.create_transaction(
    customer_uid: @uid, # ID for the user in client database
    template_key: berbix_config['template_key'], # Template key for this transaction
  )

  # To avoid dealing with a DB for this demo, we'll write the refresh token to a file
  File.open("refresh_token.txt", "w") do |file|
    file.write(@transaction_tokens.refresh_token)
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