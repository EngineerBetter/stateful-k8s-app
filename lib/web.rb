require "sinatra/base"
require "redis"
require "redis-namespace"

require "json"
require "ostruct"
require "securerandom"

REDIS = Redis::Namespace.new("k8s-app", redis: Redis.new(
  host: ENV.fetch("REDIS_SERVICE_SERVICE_HOST"),
  password: nil,
  port: ENV.fetch("REDIS_SERVICE_SERVICE_PORT", 6379)
))

class Web < Sinatra::Base
  helpers do
    def addr
      @addr =
        [
          env.fetch("SERVER_NAME", "127.0.0.1"),
          env.fetch("SERVER_PORT", "*"),
        ].join(":")
    end
  end

  get "/" do
    @total_instance_responses = REDIS.incr("total_instance_#{addr}_responses")
    @total_app_responses = REDIS.incr("total_app_responses")
    erb :index
  end

end
