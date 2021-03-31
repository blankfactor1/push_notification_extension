FROM ruby:2.6.3
RUN apt-get update -qq && apt-get install -y nodejs
WORKDIR /pwr
COPY . .
RUN gem install bundler -v '1.17.3'
RUN bundle config github.https true
RUN bundle config git.allow_insecure true
RUN bundle install

CMD ["bundle", "exec", "rake", "test"]
