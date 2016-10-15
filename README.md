# AdobeMediaEncoder

    A library for interacting with the Adobe Media Encoder API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'adobe_media_encoder'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install adobe_media_encoder

## Command Line Utilitie(s)

### AME API CLI [bin/ame_api](./bin/ame_api)
An executable to interact with the Adobe Media Encoder API using a Command Line Interface



###  Start AME service from the Mac Command Line

cd '/Applications/Adobe Media Encoder CC 2015.3/Adobe Media Encoder CC 2015.app/Contents/ame_webservice_console.app/Contents/MacOS/';./ame_webservice_console 


###  Configure the Web Server ports

vi /Applications/Adobe\ Media\ Encoder\ CC\ 2015.3/Adobe\ Media\ Encoder\ CC\ 2015.app/Contents/ame_webservice_config.ini


#### Usage
        --host-address HOSTADDRESS   The AME API server address.
                                      default: localhost
        --host-port PORT             The port on the AME API server to connect to.
                                      default: 8080
        --method-name METHODNAME
        --method-arguments JSON
        --pretty-print
        --log-to FILENAME            Log file location.
                                      default: STDERR
        --log-level LEVEL            Logging level. Available Options: debug, info, warn, error, fatal
                                      default: warn
        --[no-]options-file [FILENAME]
                                     Path to a file which contains default command line arguments.
                                      default: ~/.options/ame_api
    -h, --help                       Show this message.

#### Examples of Usage

    job_abort
    ame_api --host-address localhost --host-port 8080 --method-name job_abort
    ame_api --host-address localhost --host-port 8080 --method-name job_abort --method-arguments '{"jobId":""}'

    job_history
    ame_api --host-address localhost --host-port 8080 --method-name job_history

    job_status
    ame_api --host-address localhost --host-port 8080 --method-name job_status

    job_submit
    ame_api --host-address localhost --host-port 8080 --method-name job_status --method-arguments '{"SourcePresetPath":"","SourceFilePath":"","DestinationPath":"","OverwriteDestinationIfPresent":"","NotificationTarget":"","BackupNotificationTarget":"","NotificationRateInMilliseconds":""}'

    server_kill
    ame_api --host-address localhost --host-port 8080 --method-name server_kill

    server_restart
    ame_api --host-address localhost --host-port 8080 --method-name server_restart

    server_status
    ame_api --host-address localhost --host-port 8080 --method-name server_status


## Contributing

1. Fork it ( https://github.com/XPlatform-Consulting/adobe_media_encoder.git/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
