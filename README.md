# Teh S3 Bucketeers


## Installation

Install `awscli`:

```
apt install awscli
```

Make sure you have AWS credentials set up, see Requirements.

Clone this repo and you're good to go:

```
git clone https://github.com/tomdev/teh_s3_bucketeers.git
```

## Requirements

https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html#setup-credentials-setting

Create an AWS account and set up your access tokens in ~/.aws/credentials like this:

```name=~/.aws/credentials
[default]
aws_access_key_id = <key>
aws_secret_access_key = <secret>
```


## Usage

You can test multiple targets at the same time, use a space as a delimiter.

```
./bucketeer.sh <target> <target>
```

A result file named `results-<target>-<timestamp>.txt` will be created when an accessible bucket has been found.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomdev/teh_s3_bucketeers.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
