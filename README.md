# Berbix Demo Using Ruby & Sinatra

## Introduction
Integrating with Berbix is easy!  This guide will have you up & running in no time.  This guide assumes you have Ruby version 2.6.5 installed in your local development environment.

## Disclaimer
This code / Sinatra app is just a demo to show you how to get started with a Berbix integration.  It is not intended to be used in production.

## Quick Start Guide
- [ ] Start by cloning this repo:
```
git clone git@github.com:berbix/berbix-ruby-sinatra-demo.git
```

- [ ] Login to the Berbix console: https://dashboard.berbix.com/login

- [ ] Generate API keys following these instructions: https://docs.berbix.com/docs/settings#section-api-keys

- [ ] Enable "Test" mode with the slider in the top right hand corner of the Berbix Dashboard.

- [ ] Whitelist the development domain for this app.  Go to Settings (the gear icon in the top right corner of the Berbix Dashboard) —> Domains —> Add Domain —> “http://localhost:4567”

- [ ] Copy your template key from the "Templates" tab in the Berbix Dashboard into the berbix_config.yaml file.

- [ ] Add your last name (as on your ID that you'll be testing with) to your list of Test IDs.  Go to Settings —> Test IDs -> Add Test ID.

- [ ] Rename `berbix_config.yaml.example` to `berbix_config.yaml` and update it with your credentials.

- [ ] To start the server and run this app:
```
bundle
bundle exec ruby app.rb
```
- [ ] Then navigate to `http://localhost:4567` in your browser.

## Step-by-step Tutorial
For a walk through of how we built this app, check out our [step-by-step tutorial](./step-by-step-tutorial.md).
