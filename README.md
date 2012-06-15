NAME

  ledis

 
SYNOPSIS

  a K.I.S.S auto-rotating redis logger for ruby/rails

  Ruby
 
    redis = Redis.new
   
    logger = Ledis.logger redis
 
    logger = Ledis.new
 
    logger = Ledis.new do |config|

      config.redis = Redis.new

      config.list = 'teh_foo:log'

      config.cap = 2 ** 16

    end
 
  Rails
 
    ### file: config/environments/development.rb
 
    config.logger = Ledis.logger do |logger|
 
      logger.list = "teh_rails_app:#{ Rails.env }:log"
 
    end
 
 
DESCRIPTION

  ledis logs yo shiznit to redis.  it's got built in logic to auto-truncate
  logs when they get to big

    logger.truncate(2 **16)

  and to grab the most recent ones

    puts logger.tail(1024)

  it's list/line oriented, just like a log file and makes no attempt to
  annotated log lines or add fancy data structures to them

INSTALL

  gem 'ledis'

