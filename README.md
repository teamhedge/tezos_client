# TezosClient

[![Maintainability](https://api.codeclimate.com/v1/badges/54ab3bbbdc10c1faf933/maintainability)](https://codeclimate.com/github/moneytrackio/tezos_client/maintainability)

[![Build Status](https://travis-ci.org/moneytrackio/tezos_client.svg?branch=master)](https://travis-ci.org/moneytrackio/tezos_client)

Tezos Client interracts with tezos nodes using RPC commands. 

## Requirements:
Tezos client requires liquidity to be installed in order to work properly.
For installing on linux, you can basically follow the steps coded in travis-script folder. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tezos_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tezos_client

## Usage

### Transfer funds

```ruby 
client = TezosClient.new 

client.transfer(
    amount: 1,
    from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
    to: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
    secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
)
```

### Call a contract

```ruby
client = TezosClient.new  
client.transfer(
    amount: 5,
    from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
    to: "KT1MZTrMDPB42P9yvjf7Cy8Lkjxjj4jetbCt",
    secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
    parameters: '"pro"'
)
```

### Originate a contract written in liquidity

```ruby
script = File.expand_path("./spec/fixtures/demo.liq")
source = "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq"
secret_key = "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN"
amount =  0
init_params = '"test"'
client = TezosClient.new

res = client.originate_contract(
    from: source,
    amount: amount,
    script: script,
    secret_key: secret_key,
    init_params: init_params
)

puts "Origination operation: #{res[:operation_id]}"
puts "Contract address: #{res[:originated_contract]}"
```

### Call a contract written in liquidity
```ruby
TezosClient.new.call_contract(
  from: "tz1ZWiiPXowuhN1UqNGVTrgNyf5tdxp4XUUq",
  amount: 0,
  script: File.expand_path("./spec/fixtures/demo.liq"),
  secret_key: "edsk4EcqupPmaebat5mP57ZQ3zo8NDkwv8vQmafdYZyeXxrSc72pjN",
  to: "KT1STzq9p2tfW3K4RdoM9iYd1htJ4QcJ8Njs",
  parameters: [ "manage", "(Some { destination = tz1YLtLqD1fWHthSVHPD116oYvsd4PTAHUoc; amount = 1tz })" ]
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tezos_client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TezosClient project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/tezos_client/blob/master/CODE_OF_CONDUCT.md).
