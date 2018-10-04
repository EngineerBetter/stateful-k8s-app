# frozen_string_literal: true

require 'sinatra/base'
require 'redis'
require 'redis-namespace'

require 'json'
require 'ostruct'
require 'securerandom'

unless ENV['REDIS_SERVICE_SERVICE_HOST'].nil?
  REDIS = Redis::Namespace.new('k8s-app', redis: Redis.new(
    host: ENV.fetch('REDIS_SERVICE_SERVICE_HOST'),
    password: nil,
    port: ENV.fetch('REDIS_SERVICE_SERVICE_PORT', 6379)
  ))
end

class Web < Sinatra::Base
  helpers do
    def addr
      @addr =
      [
        env.fetch('SERVER_NAME', '127.0.0.1'),
        env.fetch('SERVER_PORT', '*')
      ].join(':')
    end

    def stop
      ->() {
        pid = Process.pid
        signal = "INT"
        puts "Killing process #{pid} with signal #{signal}"
        Process.kill(signal, pid)
      }
    end
  end

  enable :sessions if ENV['REDIS_SERVICE_SERVICE_HOST'].nil?
  get '/' do
    if ENV['REDIS_SERVICE_SERVICE_HOST'].nil?
      session[:instance_responses] = 0 if session[:instance_responses].nil?
      session[:app_responses] = 0 if session[:app_responses].nil?
      @total_instance_responses = session[:instance_responses] + 1
      @total_app_responses = session[:app_responses] + 1
      session[:instance_responses] = @total_instance_responses
      session[:app_responses] = @total_app_responses
    else
      @total_instance_responses = REDIS.incr("total_instance_#{addr}_responses")
      @total_app_responses = REDIS.incr('total_app_responses')
    end
    erb :index
  end

  get '/crash' do
    REDIS.set("total_instance_#{addr}_responses", 0, :xx => true) if ENV['REDIS_SERVICE_SERVICE_HOST']
    stop.call
    %(
      <h2>Oh no! I've crashed!</h2>
      <h3><a href="/">Check if an app instance is available</a></h3>
    )
  end
end
