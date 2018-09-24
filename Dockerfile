FROM ruby:2.5.1

RUN mkdir app

WORKDIR /app

COPY ./ /app/

EXPOSE 9292

RUN bundle install

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0"]
