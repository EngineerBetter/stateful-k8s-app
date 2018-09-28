require "sinatra/base"
require "redis"
require "redis-namespace"

require "json"
require "ostruct"
require "securerandom"

unless ENV['REDIS_SERVICE_SERVICE_HOST'].nil?
  REDIS = Redis::Namespace.new("k8s-app", redis: Redis.new(
    host: ENV.fetch("REDIS_SERVICE_SERVICE_HOST"),
    password: nil,
    port: ENV.fetch("REDIS_SERVICE_SERVICE_PORT", 6379)
  ))
end

class Web < Sinatra::Base
  enable :sessions
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
    if ENV['REDIS_SERVICE_SERVICE_HOST'].nil?
      if session[:total_instance_responses].nil?
        session[:total_instance_responses] = 0
      end
      if session[:total_app_responses].nil?
        session[:total_app_responses] = 0
      end
      @total_instance_responses = session[:total_instance_responses] + 1
      @total_app_responses = session[:total_app_responses] + 1
      session[:total_instance_responses] = @total_instance_responses
      session[:total_app_responses] = @total_app_responses
    else
      @total_instance_responses = REDIS.incr("total_instance_#{addr}_responses")
      @total_app_responses = REDIS.incr("total_app_responses")
    end
    erb :index
  end

end
