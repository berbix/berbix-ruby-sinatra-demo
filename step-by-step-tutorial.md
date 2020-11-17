# Tutorial: Getting Started with Berbix, Step-by-Step

Getting started with a Berbix integration for ID verification is super simple.  This tutorial will walk you through, step-by-step, getting Berbix working with a barebones Sinatra app.

## Getting 'Hello, world!' running on Sinatra:

Install the `sinatra` and `sinatra-reloader` Ruby gems:

```
gem install sinatra
gem install sinatra-reloader
```

Create a folder called `berbix-demo` (this will be the root project folder)

Create a new Sinatra app by making a file called `app.rb`.  In this file, add the following code:

```ruby
require 'sinatra'
require 'sinatra/reloader' if development?

get '/' do
  erb :index
end
```

Create a `views` folder, and add a file called `index.erb`

```html
<html>
<title>Berbix Tutorial</title>
<body>

<h1>Hello, world!</h1>

</body>
</html>
```

Run the Sinatra app with the following command from the project folder:

```
ruby app.rb
```

View at: http://localhost:4567 and you should see "Hello, world!"

## Getting Berbix up and running:

Now, let's install the `berbix` Ruby gem which will act as our SDK and handle making backend calls to the Berbix API.  If you are curious, the source code for the gem lives at [https://github.com/berbix/berbix-ruby](https://github.com/berbix/berbix-ruby)

```
gem install berbix
```

Add it to `app.rb`
```ruby
require 'berbix'
```

Now let's create a config file to store the API key from the Berbix dashboard.  In the project folder, create a file called `berbix_config.yaml` with the following contents:

```yaml
--- 
 client_secret: "REPLACE_WITH_YOUR_CLIENT_SECRET"
 template_key: "REPLACE_WITH_YOUR_TEMPLATE_KEY"
```

And make sure to include the following in `app.rb` so we can read the YAML file:

```ruby
require 'yaml'
```

Now's let login to the Berbix dashboard to get the necessary credentials and configuration items at https://dashboard.berbix.com/login

Generate API keys following these instructions: https://docs.berbix.com/docs/settings#section-api-keys

Create a template: https://docs.berbix.com/docs/templates

Copy and paste the API key and template key from the Berbix dashboard to the `berbix_config.yaml` file.

While in the Berbix console, make the following other changes:
1. Enable "Test" mode with the slider in the top right hand corner of the Dashboard.  Details on "Live" vs "Test" mode are available [here](https://docs.berbix.com/docs/modes).
1. Whitelist the development domain for this app. Go to Settings (the gear icon in the top right corner of the Berbix Dashboard) —> Domains —> Add Domain —> “http://localhost:4567” (Note: only `https` URLs are allowed in production)
1. Add your last name (as on your ID that you'll be testing with) to your list of Test IDs. Go to Settings —> Test IDs -> Add Test ID.

Now, let's create an instance of the Berbix client in `app.rb`. We will also create a 'transaction' which we will just store in a flat-file for this demo. In production, you'll probably want to store the transaction in something else like a database.  We'll also just use a random number as a user ID for this demo.

```ruby
require 'sinatra'
require 'sinatra/reloader' if development?
require 'berbix'
require 'yaml'

berbix_config = YAML.load(File.read('berbix_config.yaml'))

get '/' do
  @uid = rand(10000000000)

  client = Berbix::Client.new(
    api_secret: berbix_config['client_secret'],
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
```

Now, let's update the view file `index.erb` to load the Berbix Javascript SDK:

```html
<html>
<title>Berbix Tutorial</title>
<body>

<h1>Hello, world!</h1>

<p>Please click the button below to verify your ID with Berbix:</p>
<button id="myButton">Verify Me</button>
<div id="berbix-root" style="width:500px;"></div>

<script src="https://sdk.berbix.com/latest/berbix-verify.js"></script>

<script>
  var handler = BerbixVerify.configure({
    onComplete: function() {
        alert('Berbix verification complete.  Click OK to see the results.');
        window.location.href = "/after_id_check";
    },
  })

  document.getElementById('myButton').addEventListener('click', function(e) {
    handler.open({
      clientToken: '<%= @transaction_tokens.client_token %>',
      root: 'berbix-root'
    });
  });
</script>

</body>
</html>
```

At this point, you should be able to start the server and see the Berbix flow when you click the "Verify Me" button.  If you complete the Berbix flow at this point, you will get an error because we haven't implemented the page `after_id_check`, so let's do that now.

## Handling the response from Berbix:

Let's create an action in `app.rb`:

```ruby
get '/after_id_check' do
  @refresh_token = File.open('./refresh_token.txt', &:readline).gsub(/\s+/, "")

  client = Berbix::Client.new(
    client_secret: berbix_config['client_secret'],
  )

  transaction_tokens = Berbix::Tokens.from_refresh(@refresh_token)
  
  @data = client.fetch_transaction(transaction_tokens)

  erb :after_id_check
end
```

and a corresponding view file in `views/after_id_check.erb`:

```html
<html>
<title>Berbix Tutorial</title>
<body>

<h1>Hello, world!</h1>

<pre>
<%= @data.to_yaml %>
</pre>

</body>
</html>
```

There you have it.  You should now see the raw response data from Berbix's backend after going through the flow and being redirected to the `/after_id_check` page.

## Verifying a user:

In this simple demo app, let's now create a name to compare against the name extracted from the ID in the response from Berbix.

Install the `namey` gem and use it to generate a random name on the index page.

```
gem install namey
```

And add to the top of `app.rb`
```ruby
require 'namey'
```

And in the `/` block in `app.rb`:
```ruby
@generator = Namey::Generator.new
@username = @generator.name(:common)
```

And in the view file `index.erb`, let's greet the user with their name, changing "Hello, world!" to:
```html
<h1>Hello, <%= @username %>!</h1>
```

And in the JS part of `index.erb`, change the redirect to pass along the username in the URL params:
```javascript
window.location.href = "/after_id_check?username=<%= @username %>";
```

Now in the block for `after_id_check` in `app.erb`, we can compare this generated name with the name returned from the Berbix API:
```ruby
@name_on_id = @data["fields"]["given_name"]["value"] + " " + @data["fields"]["family_name"]["value"]
@name_match = @name_on_id.casecmp?(params[:username])
```

This is a very simple, contrived example, just for demonstration purposes only.  For more information on the data returned by the Berbix API, please refer to the far right hand column in this document: [https://docs.berbix.com/reference#gettransactionmetadata](https://docs.berbix.com/reference#gettransactionmetadata)

Finally, to see the results on the `after_id_check` page, let's add the following:
```html
<p>Name on submitted ID: <%= @name_on_id %></p>

<% if @name_match %>
  <p class="success">Names match!</p>
<% else %>
  <p class="fail">Names do not match!</p>
<% end %>
```
