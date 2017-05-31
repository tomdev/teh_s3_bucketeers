# Teh S3 Bucketeers


## Installation

Install `awscli`:

```
apt install awscli
```

Make sure you have AWS credentials set up, see Requirements.

Clone this repo and you're good to go:

```
git clone git@github.com:tomdev/teh_s3_bucketeers.git
```

## Requirements

Create a AWS account and set up your access tokens in ~./aws/credentials like this:

```name=~/.aws/credentials
[default]
aws_access_key_id = <key>
aws_secret_access_key = <secret>
```

## Usage

```
./bucketeer.sh <target>
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomdev/teh_s3_bucketeers.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
